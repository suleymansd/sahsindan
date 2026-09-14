import { createHmac } from "node:crypto";
import { expect, test } from "@playwright/test";

test("administrator requires a code, can retry and retains the MFA session", async ({ page, context }, testInfo) => {
  await context.setExtraHTTPHeaders({ "x-e2e-test-id": testInfo.testId });
  await page.goto("/giris/admin");
  await page.getByLabel("E-posta", { exact: true }).fill("e2e3@example.com");
  await page.getByLabel("Şifre", { exact: true }).fill("E2ePass123!");
  await page.getByRole("button", { name: "Giriş Yap", exact: true }).click();
  await expect(page.getByRole("alert").filter({ hasText: "6 haneli kodu" })).toBeVisible();
  await page.getByLabel("Doğrulayıcı uygulama kodu").fill("abcdef");
  await page.getByRole("button", { name: "Giriş Yap", exact: true }).click();
  await expect(page).toHaveURL(/\/giris\/admin$/);
  const counter = Buffer.alloc(8);
  counter.writeBigUInt64BE(BigInt(Math.floor(Date.now() / 30000)));
  const digest = createHmac("sha1", "12345678901234567890").update(counter).digest();
  const code = ((digest.readUInt32BE(digest[19] & 15) & 0x7fffffff) % 1000000).toString().padStart(6, "0");
  await page.getByLabel("Doğrulayıcı uygulama kodu").fill(code);
  await page.getByRole("button", { name: "Giriş Yap", exact: true }).click();
  await expect(page).toHaveURL(/\/admin(?:\/.*)?$/);
  await page.reload();
  await expect(page).toHaveURL(/\/admin(?:\/.*)?$/);
  await expect(page.getByRole("heading").first()).toBeVisible();
});
