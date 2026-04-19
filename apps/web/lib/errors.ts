import { UI } from "@/lib/strings";

export function toFriendlyError(error: unknown): string {
  if (error instanceof Error) {
    const message = error.message;
    if (message.includes("Invalid credentials")) return "E-posta veya şifre hatalı.";
    if (message.includes("Email already registered")) return "Bu e-posta zaten kayıtlı.";
    if (message.includes("Phone already registered")) return "Bu telefon zaten kayıtlı.";
    if (message.includes("Invalid OTP")) return "Doğrulama kodu hatalı.";
    if (message.includes("Consent required")) return "Lütfen onay kutusunu işaretleyin.";
    if (message.includes("Listing not available")) return "İlan uygun değil.";
    if (message.includes("Verification required")) return "Doğrulama gerekli.";
    if (message.includes("Request failed")) return UI.errors.generic;
    return message;
  }
  return UI.errors.generic;
}
