import { test, expect } from "@playwright/test";

test("public pages disclose unavailable transactions without backend requests", async ({ page }) => {
  const apiRequests: string[] = [];
  page.on("request", (request) => {
    const url = new URL(request.url());
    if (url.pathname.startsWith("/api/") || url.port === "8080") apiRequests.push(url.href);
  });
  await page.goto("/");
  await expect(page.getByRole("status")).toContainText("Tanıtım yayını");
  await expect(page.getByRole("heading", { name: "İyi bir alışveriş, iyi bir tanışmayla başlar." })).toBeVisible();
  await page.goto("/giris/kullanici");
  await expect(page.getByRole("button", { name: "Giriş Yap", exact: true })).toBeDisabled();
  await page.goto("/uye-ol");
  await expect(page.locator('button[type="submit"]')).toBeDisabled();
  await page.goto("/sifre-unuttum");
  await expect(page.getByRole("button", { name: "Sıfırlama Bağlantısı Gönder" })).toBeDisabled();
  expect(apiRequests).toEqual([]);
});

test("mobile presentation stays within the viewport", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  await expect(page.getByRole("status")).toBeVisible();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
});
