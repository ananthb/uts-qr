import * as aesjs from "aes-js";
import QRCode from "qrcode/lib/server";

export async function onRequestGet({ request, env }) {
	const { searchParams } = new URL(request.url);
	const name = searchParams.get("name");
	const code = searchParams.get("code");
	const latitude = searchParams.get("latitude");
	const longitude = searchParams.get("longitude");

	if (!code || !name || !latitude || !longitude) {
		return new Response("missing parameters", {
			status: 400,
		});
	}

	// Create a QR code with the given parameters;
	const text = encrypt(env.UTS_QR_KEY, `${name.toUpperCase()}:${code.toUpperCase()}:${latitude}:${longitude}`);
	const qrCode = await QRCode.toString(text, { type: "svg" });
	return new Response(qrCode, { headers: { "Content-Type": "image/svg+xml" } });
}

/**
 *
 * Encrypt strings using AES-128 ECB and PKCS7 padding.
 * The returned string is base64 encoded.
 *
 * @param {string} key The key to encrypt the string with.
 * @param {string} input The string to encrypt
 * @returns {string} The encrypted string
 */
function encrypt(key, input) {
	const value = input.trim();
	const keyBuffer = aesjs.utils.utf8.toBytes(key.trim());
	const inputBuffer = aesjs.padding.pkcs7.pad(aesjs.utils.utf8.toBytes(value));

	const escEcb = new aesjs.ModeOfOperation.ecb(keyBuffer);
	const encryptedBytes = escEcb.encrypt(inputBuffer);

	const encryptedData = Buffer.from(encryptedBytes).toString('base64');
	return encryptedData;
};
