import { expect, test, type Page } from "@playwright/test";

test.beforeEach(async ({ context }, testInfo) => {
  await context.setExtraHTTPHeaders({ "x-e2e-test-id": testInfo.testId });
});

async function login(
  page: Page,
  email = "e2e0@example.com",
  password = "E2ePass123!",
) {
  await page.getByLabel("E-posta", { exact: true }).fill(email);
  await page.getByLabel("Şifre", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Giriş Yap", exact: true }).click();
}

test("login, browse, favorite and reload preserve the session", async ({
  page,
}) => {
  await page.goto("/giris/kullanici");
  await login(page);
  await expect(page).toHaveURL(/\/app$/);
  await page.goto("/ilanlar/1");
  await expect(
    page.getByRole("heading", { name: "Audit E2E Car", exact: true }),
  ).toBeVisible();
  const favorite = page.waitForResponse(
    (r) =>
      r.url().endsWith("/listings/1/favorite") &&
      r.request().method() === "POST",
  );
  await page
    .getByRole("button", { name: "Favorilere Ekle", exact: true })
    .click();
  expect((await favorite).status()).toBe(200);
  await page.goto("/favoriler");
  await expect(page.getByText("Audit E2E Car", { exact: true })).toBeVisible();
  await page.reload();
  await expect(page.getByText("Audit E2E Car", { exact: true })).toBeVisible();
});

test("invalid password displays an error without redirecting", async ({
  page,
}) => {
  await page.goto("/giris/kullanici");
  await login(page, "e2e0@example.com", "WrongPass123!");
  await expect(
    page.getByRole("alert").filter({ hasText: /hatalı|geçersiz/i }),
  ).toBeVisible();
  await expect(page).toHaveURL(/\/giris\/kullanici$/);
});

test("wrong role clears the server session", async ({ page, context }) => {
  await page.goto("/giris/kullanici");
  await login(page, "e2e2@example.com");
  await expect(
    page.getByRole("alert").filter({ hasText: "doğru giriş panelini seç" }),
  ).toBeVisible();
  expect(
    (await context.cookies()).some((cookie) => cookie.name === "refresh_token"),
  ).toBe(false);
});

test("login rejects external redirect targets", async ({ page }) => {
  await page.goto(
    "/giris/kullanici?redirect=" + encodeURIComponent("//example.com"),
  );
  await login(page);
  await expect(page).toHaveURL("http://127.0.0.1:3080/app");
});

test("search applies on submit and clearing filters restores listings", async ({
  page,
}) => {
  await page.goto("/giris/kullanici");
  await login(page);
  await expect(page).toHaveURL(/\/app$/);
  await page.goto("/ilanlar");
  await expect(page.locator("article")).toHaveCount(1);
  await page
    .getByLabel("İlanlarda ara", { exact: true })
    .fill("olmayan-arac-987654");
  await expect(page.locator("article")).toHaveCount(1);
  await expect(page).toHaveURL(/\/ilanlar$/);
  await page.getByRole("button", { name: "Ara", exact: true }).click();
  await expect(page).toHaveURL(/q=olmayan-arac-987654/);
  await expect(
    page.getByRole("button", { name: "Filtreleri temizle", exact: true }),
  ).toBeVisible();
  await expect(page.locator("article")).toHaveCount(0);
  await page
    .getByRole("button", { name: "Filtreleri temizle", exact: true })
    .click();
  await expect(page.locator("article")).toHaveCount(1);
});

test("narrow screen filters and menu close after navigation", async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/giris/kullanici");
  await login(page);
  await expect(page).toHaveURL(/\/app$/);
  await page.goto("/ilanlar");
  await expect(page.locator("article")).toHaveCount(1);
  await page
    .getByRole("button", { name: "Filtreleri aç", exact: true })
    .click();
  const dialog = page.getByRole("dialog");
  await dialog.getByLabel("Yakıt", { exact: true }).selectOption("Electric");
  await dialog.getByRole("button", { name: "Filtrele", exact: true }).click();
  await expect(dialog).not.toBeVisible();
  await expect(page).toHaveURL(/fuel=Electric/);
  await expect(
    page.getByRole("button", { name: "Filtreleri temizle", exact: true }),
  ).toBeVisible();
  await page
    .getByRole("button", { name: "Filtreleri temizle", exact: true })
    .click();
  await expect(page.locator("article")).toHaveCount(1);
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    ),
  ).toBe(true);
  await page.getByRole("button", { name: "Menü", exact: true }).click();
  await page
    .getByRole("navigation", { name: "Mobil menü" })
    .getByRole("link", { name: "Favoriler", exact: true })
    .click();
  await expect(page).toHaveURL(/\/favoriler$/);
  await expect(page.getByRole("dialog")).not.toBeVisible();
});

test("failed message send preserves the draft and can be retried", async ({ page }) => {
  await page.goto("/giris/kullanici");
  await login(page);
  await expect(page).toHaveURL(/\/app$/);
  await page.goto("/ilanlar/1");
  await page.getByRole("button", { name: "Mesaj Gönder", exact: true }).click();
  await page.getByRole("dialog").getByRole("textbox").fill("E2E ilk mesaj");
  await page.getByRole("button", { name: "Mesajı Gönder", exact: true }).click();
  await expect(page.getByText("Mesaj gönderildi.", { exact: true })).toBeVisible();
  await page.goto("/mesajlar");
  const draft = page.getByPlaceholder("Mesaj yaz…");
  await draft.fill("Bağlantı kesilince kaybolmamalı");
  await page.route("**/threads/*/messages", route => route.fulfill({ status: 503, contentType: "application/json", body: JSON.stringify({ error: { message: "Service unavailable" } }) }));
  await page.getByRole("button", { name: "Gönder", exact: true }).click();
  await expect(page.getByRole("alert").filter({ hasText: "Service unavailable" })).toBeVisible();
  await expect(draft).toHaveValue("Bağlantı kesilince kaybolmamalı");
  await page.unroute("**/threads/*/messages");
  await page.getByRole("button", { name: "Gönder", exact: true }).click();
  await expect(draft).toHaveValue("");
  await page.reload();
  await expect(page.getByText("Bağlantı kesilince kaybolmamalı").last()).toBeVisible();
});

test("listing upload failure retries the same draft and publishes once", async ({ page }) => {
  await page.goto("/giris/kullanici");
  await login(page, "e2e1@example.com");
  await expect(page).toHaveURL(/\/app$/);
  await page.goto("/ilan-ver");
  for (const [name, value] of Object.entries({ title: "E2E yayınlanan araç", description: "Eksiksiz ilan akışı testi", price: "250000", district: "Kadıköy", brand: "Audi", model: "A3", year: "2020", mileage: "45000", transmission: "Automatic", fuel: "Gasoline", color: "White" })) {
    await page.locator(`form [name="${name}"]`).fill(value);
  }
  await expect(page.getByRole("button", { name: "Yayınla", exact: true })).toBeDisabled();
  const image = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAI0lEQVR4nGNkYGhgIAUwkaSaYVQDcYCJSHVwMKqBGEByKAEAup8AoAnpagsAAAAASUVORK5CYII=", "base64");
  await page.locator('input[type="file"]').setInputFiles(Array.from({ length: 6 }, (_, index) => ({ name: `photo-${index}.png`, mimeType: "image/png", buffer: image })));
  let creates = 0;
  page.on("request", request => { if (request.method() === "POST" && request.url().endsWith("/listings")) creates += 1; });
  let failed = false;
  await page.route("**/listings/*/photos", route => {
    if (!failed) { failed = true; return route.fulfill({ status: 503, body: "Storage unavailable" }); }
    return route.continue();
  });
  await page.getByRole("button", { name: "Yayınla", exact: true }).click();
  await expect(page.getByText("Bazı fotoğraflar yüklenemedi. İlan taslakta kaldı.")).toBeVisible();
  await page.unroute("**/listings/*/photos");
  await page.getByRole("button", { name: "Yayınla", exact: true }).click();
  await expect(page.getByText("İlan oluşturuldu ve yayına alındı.")).toBeVisible();
  expect(creates).toBe(1);
  await expect(page.locator('[name="title"]')).toHaveValue("");
  await page.goto("/ilanlar");
  await expect(page.getByText("E2E yayınlanan araç", { exact: true })).toBeVisible();
});

test("password reset network failure restores the submit button", async ({ page }) => {
  await page.goto("/sifre-unuttum");
  await page.getByRole("textbox").fill("e2e0@example.com");
  await page.route("**/auth/forgot-password", route => route.abort("failed"));
  await page.getByRole("button", { name: /Gönder/i }).click();
  await expect(page.getByRole("alert")).toBeVisible();
  await expect(page.getByRole("button", { name: /Gönder/i })).toBeEnabled();
});

test("new member submits documents for manual review on mobile", async ({ page }, testInfo) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/uye-ol");
  for (const [name, value] of Object.entries({ name: "E2E Yeni Üye", email: "new-member@example.com", phone: "5558999001", password: "E2ePass123!" })) {
    await page.locator(`form [name="${name}"]`).fill(value);
  }
  await page.getByRole("button", { name: "Hesabı Oluştur", exact: true }).click();
  await expect(page).not.toHaveURL(/\/uye-ol$/);
  await page.goto("/dogrulama");
  await page.getByRole("button", { name: "Devam Et", exact: true }).click();
  const png = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAI0lEQVR4nGNkYGhgIAUwkaSaYVQDcYCJSHVwMKqBGEByKAEAup8AoAnpagsAAAAASUVORK5CYII=", "base64");
  await page.locator('input[type="file"]').first().setInputFiles({ name: "identity.png", mimeType: "image/png", buffer: png });
  await page.getByRole("button", { name: "Devam Et", exact: true }).click();
  await page.locator('input[type="file"]').setInputFiles({ name: "selfie.png", mimeType: "image/png", buffer: png });
  await page.getByRole("button", { name: "Devam Et", exact: true }).click();
  await page.getByRole("button", { name: "Devam Et", exact: true }).click();
  await expect(page.getByRole("button", { name: "Doğrulamayı Gönder", exact: true })).toBeDisabled();
  await page.getByRole("checkbox").check();
  await page.getByRole("button", { name: "Doğrulamayı Gönder", exact: true }).click();
  await expect(page.getByRole("status").filter({ hasText: "Başvurun alındı" })).toBeVisible();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  await page.screenshot({ path: testInfo.outputPath("mobile-verification.png"), fullPage: true, animations: "disabled" });
});

test("conversation history is paged and the latest messages remain reachable", async ({ page }, testInfo) => {
  await page.goto("/giris/kullanici");
  await login(page);
  await expect(page).toHaveURL(/\/app$/);
  await page.goto("/mesajlar");
  await expect(page.getByText("Historical message 134", { exact: true })).toBeVisible();
  await expect(page.getByText("Historical message 100", { exact: true })).toHaveCount(0);
  await page.getByRole("button", { name: "Önceki mesajlar", exact: true }).click();
  await expect(page.getByText("Historical message 100", { exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Son mesajlar", exact: true }).click();
  await expect(page.getByText("Historical message 134", { exact: true })).toBeVisible();
  await page.goto("/ilanlar");
  await expect(page.locator("article").first()).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath("desktop-listings.png"), fullPage: true, animations: "disabled" });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.screenshot({ path: testInfo.outputPath("mobile-listings.png"), fullPage: true, animations: "disabled" });
});
