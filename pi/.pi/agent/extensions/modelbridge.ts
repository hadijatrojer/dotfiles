import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const baseUrl = (
  process.env.MODELBRIDGE_BASE_URL ?? "http://127.0.0.1:3000/v1"
).replace(/\/$/, "");
const configuredApiKey = process.env.MODELBRIDGE_API_KEY || "dummy";
const verbose = /^(1|true|yes)$/i.test(
  process.env.MODELBRIDGE_EXTENSION_VERBOSE ?? "",
);

/**
 * Shape of a single entry in the bridge's `/v1/models` response.
 *
 * Source of truth: `packages/server/src/routes/models.ts` `toOpenAIModel`.
 * The bridge guarantees every field listed below; the `??` fallbacks in
 * the registration block are belt-and-braces in case an older bridge
 * (or a future schema change) drops a field.
 */
type BridgeModelCost = {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
};

type BridgeModel = {
  id: string;
  name?: string;
  context_window?: number;
  max_output_tokens?: number;
  input?: Array<"text" | "image">;
  reasoning?: boolean;
  /** providerFamily, e.g. "anthropic", "meta-anthropic", "meta-openai", "ollama" */
  provider?: string;
  /** upstreamProvider, e.g. "vertex-anthropic", "plugboard-openai" */
  upstream_provider?: string;
  /** upstreamModel id (the bare id the bridge actually sends to upstream) */
  root?: string;
  /** Public list price USD per million tokens; absent when bridge can't infer. */
  cost?: BridgeModelCost;
};

type BridgeModelsResponse = {
  object: string;
  data: BridgeModel[];
};

function isBridgeModelsResponse(value: unknown): value is BridgeModelsResponse {
  return (
    typeof value === "object" &&
    value !== null &&
    "data" in value &&
    Array.isArray((value as { data?: unknown }).data)
  );
}

function unreachableBridgeError(baseUrl: string, cause: unknown): Error {
  const detail = cause instanceof Error ? cause.message : String(cause);
  return new Error(
    `modelbridge extension cannot reach ${baseUrl}/models. ` +
      `Is the bridge running? Try \`pnpm --filter @modelbridge/server dev\` ` +
      `in the modelbridge checkout, or set MODELBRIDGE_BASE_URL to a reachable URL. ` +
      `Underlying error: ${detail}`,
  );
}

function unauthorizedError(baseUrl: string): Error {
  return new Error(
    `modelbridge rejected /models with 401 Unauthorized. ` +
      `Start pi with MODELBRIDGE_API_KEY set to the same value used by the server, ` +
      `or disable server auth (unset MODELBRIDGE_API_KEY on the bridge). baseUrl=${baseUrl}`,
  );
}

function fetchFailedError(
  baseUrl: string,
  res: Response,
  json: unknown,
  rawText: string,
): Error {
  const message =
    typeof json === "object" && json && "error" in json
      ? JSON.stringify((json as { error?: unknown }).error)
      : rawText.slice(0, 500);
  return new Error(
    `Failed to fetch modelbridge models from ${baseUrl}/models: ` +
      `${res.status} ${res.statusText}${message ? ` - ${message}` : ""}`,
  );
}

export default async function (pi: ExtensionAPI) {
  let res: Response;
  try {
    res = await fetch(`${baseUrl}/models`, {
      headers: { Authorization: `Bearer ${configuredApiKey}` },
    });
  } catch (cause) {
    throw unreachableBridgeError(baseUrl, cause);
  }

  const rawText = await res.text();
  let json: unknown;
  try {
    json = rawText ? JSON.parse(rawText) : {};
  } catch {
    throw new Error(
      `modelbridge /models returned invalid JSON (${res.status}): ${rawText.slice(0, 500)}`,
    );
  }

  if (!res.ok) {
    if (res.status === 401) throw unauthorizedError(baseUrl);
    throw fetchFailedError(baseUrl, res, json, rawText);
  }

  if (!isBridgeModelsResponse(json)) {
    throw new Error(
      `modelbridge /models response did not contain a data array: ${rawText.slice(0, 500)}`,
    );
  }

  const models = json.data;

  // Track unpriced ids so we can surface a single summary line at startup.
  // The bridge ships a `cost` field for every id it can identify; anything
  // missing is either an unknown family (e.g. grok-4 today) or a future id
  // we have not yet added to MODEL_METADATA / inferModelCost. Pi requires a
  // `cost` object on every model, so we fill in a free-zero block as a last
  // resort and tag the display name so the picker is honest about it.
  const unpriced: string[] = [];

  pi.registerProvider("modelbridge", {
    baseUrl,
    apiKey: configuredApiKey,
    api: "openai-responses",
    models: models.map((m) => {
      // Surface the upstream provider in the display name so the picker
      // distinguishes "anthropic/claude-opus-4-7" (Vertex) from
      // "meta-anthropic/claude-opus-4.6" (Plugboard) at a glance.
      const upstream = m.upstream_provider ?? m.provider;
      const upstreamSuffix = upstream ? ` [${upstream}]` : "";
      const baseName = m.name ?? m.id;
      const hasBridgeCost = m.cost !== undefined;
      if (!hasBridgeCost) unpriced.push(m.id);
      const unpricedSuffix = hasBridgeCost ? "" : " [unpriced]";
      return {
        id: m.id,
        name: `${baseName}${upstreamSuffix}${unpricedSuffix} via modelbridge`,
        reasoning: Boolean(m.reasoning),
        input: m.input?.length ? m.input : ["text"],
        contextWindow: m.context_window ?? 128_000,
        maxTokens: m.max_output_tokens ?? 16_384,
        // Forward bridge-supplied list price when present so pi displays real
        // cost numbers in the footer / `/session`. Falls back to free zeros
        // for models the bridge could not identify; the [unpriced] tag in the
        // display name keeps the user from mistaking that for a free model.
        cost: m.cost ?? { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      };
    }),
  });

  if (verbose) {
    // eslint-disable-next-line no-console
    console.log(
      `[modelbridge extension] registered ${models.length} model(s) from ${baseUrl}` +
        (unpriced.length > 0
          ? ` (${unpriced.length} unpriced: ${unpriced.slice(0, 5).join(", ")}${unpriced.length > 5 ? ", ..." : ""})`
          : ""),
    );
  }
}
