export function normalizePaymentStatus(raw: unknown): string {
  const status = String(raw ?? "").trim().toLowerCase();
  if (!status) return "";
  if (status === "cancelled" || status === "cancelado") return "canceled";
  return status;
}

type LastPaymentResult = {
  status: string | null;
  paidAt: string | null;
};

type MpInvoice = Record<string, unknown>;

function invoiceTimestamp(invoice: MpInvoice): number {
  const raw = invoice.debit_date ??
    invoice.last_modified ??
    invoice.date_created ??
    0;
  const value = new Date(String(raw)).getTime();
  return Number.isFinite(value) ? value : 0;
}

function pickRelevantInvoice(results: MpInvoice[]): MpInvoice | null {
  if (results.length === 0) return null;

  const now = Date.now();
  const ranked = results.map((invoice) => {
    const payment = invoice.payment && typeof invoice.payment === "object"
      ? (invoice.payment as Record<string, unknown>)
      : null;
    const paymentStatus = normalizePaymentStatus(payment?.status);
    const invoiceStatus = normalizePaymentStatus(invoice.status);
    const summarized = normalizePaymentStatus(invoice.summarized);
    const debitTs = invoiceTimestamp(invoice);

    let score = 0;
    if (paymentStatus === "rejected") score = 100;
    else if (paymentStatus === "canceled" || paymentStatus === "cancelled") {
      score = 95;
    } else if (paymentStatus === "in_process") score = 90;
    else if (paymentStatus === "approved") score = 85;
    else if (invoiceStatus === "processed") score = 80;
    else if (summarized === "rejected" || summarized === "pending") score = 75;
    else if (debitTs > 0 && debitTs <= now) score = 70;
    else if (invoiceStatus === "scheduled") score = 20;

    return { invoice, score, debitTs };
  });

  ranked.sort((a, b) => b.score - a.score || b.debitTs - a.debitTs);
  return ranked[0]?.invoice ?? results[0];
}

function resolveInvoicePaymentStatus(invoice: MpInvoice): string {
  const payment = invoice.payment && typeof invoice.payment === "object"
    ? (invoice.payment as Record<string, unknown>)
    : null;
  const paymentStatus = normalizePaymentStatus(payment?.status);
  if (paymentStatus) return paymentStatus;

  const summarized = normalizePaymentStatus(invoice.summarized);
  if (summarized === "rejected") return "rejected";
  if (summarized === "pending") return "in_process";

  const invoiceStatus = normalizePaymentStatus(invoice.status);
  if (invoiceStatus === "processed") return "in_process";
  if (invoiceStatus === "canceled" || invoiceStatus === "cancelled") {
    return "canceled";
  }

  return "";
}

async function fetchPaymentStatus(
  accessToken: string,
  paymentId: unknown,
): Promise<string> {
  const id = String(paymentId ?? "").trim();
  if (!id) return "";

  const response = await fetch(`https://api.mercadopago.com/v1/payments/${id}`, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
  });
  if (!response.ok) return "";

  const data = await response.json().catch(() => ({}));
  return normalizePaymentStatus(data?.status);
}

/** Busca o status do pagamento mais recente vinculado ao preapproval. */
export async function fetchLastAuthorizedPayment(
  accessToken: string,
  preapprovalId: string,
): Promise<LastPaymentResult> {
  const url = new URL("https://api.mercadopago.com/authorized_payments/search");
  url.searchParams.set("preapproval_id", preapprovalId);
  url.searchParams.set("limit", "50");

  const response = await fetch(url.toString(), {
    method: "GET",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
  });

  if (!response.ok) {
    return { status: null, paidAt: null };
  }

  const data = await response.json().catch(() => ({}));
  const results = Array.isArray(data?.results)
    ? (data.results as MpInvoice[])
    : [];
  if (results.length === 0) {
    return { status: null, paidAt: null };
  }

  const invoice = pickRelevantInvoice(results);
  if (!invoice) {
    return { status: null, paidAt: null };
  }

  const payment = invoice.payment && typeof invoice.payment === "object"
    ? (invoice.payment as Record<string, unknown>)
    : null;

  let status = resolveInvoicePaymentStatus(invoice);
  if (!status || status === "in_process") {
    const fetched = await fetchPaymentStatus(accessToken, payment?.id);
    if (fetched) status = fetched;
  }

  const paidAt = String(
    payment?.date_approved ??
      payment?.date_created ??
      invoice.debit_date ??
      invoice.last_modified ??
      invoice.date_created ??
      "",
  ).trim() || null;

  return { status: status || null, paidAt };
}
