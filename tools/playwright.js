// ------------------------------------------------------------------
// Load a single application webpage as if in a browser
// ------------------------------------------------------------------

// System includes
const fs = require('fs'); // Import the fs module

// Playwright firefox browser
const { firefox } = require('playwright'); // Import Firefox support

// Function to parse `curl` cookie file

function parseCurlCookies(filePath) {
    const cookies = [];
    const lines = fs.readFileSync(filePath, 'utf-8').split('\n');

    for (const line of lines) {
        // Skip comments and empty lines
        if (line.startsWith('# ') || !line.trim()) continue;

        const [domain, flag, path, secure, expiry, name, value] = line.split(/\s+/);

        cookies.push({
            name,
            value,
            domain,
            path,
            secure: secure === 'TRUE',
            expires: Number(expiry),
        });
    }

    return cookies;
}

// SPA loading workflow

(async () => {

    const url = process.argv[2]; // URL to visit
    const cookiesFile = process.argv[3]; // Optional cookies file

    const browser = await firefox.launch({ headless: true }); // Launch Firefox in headless mode
    const context = await browser.newContext();

    if (cookiesFile) {
    
        console.error(`Loading cookies from ${cookiesFile}`);
        const cookies = parseCurlCookies(cookiesFile);
        await context.addCookies(cookies);
    
    } else {

        console.error('No cookies provided, proceeding without cookies.');

    }


    const page = await context.newPage();

    await page.goto(url, { waitUntil: 'networkidle' }); // Navigate to the URL

    const html = await page.content(); // Get the rendered HTML
    console.log(html); // Print the HTML to stdout

    await context.close();
    await browser.close(); // Close the browser

})();
