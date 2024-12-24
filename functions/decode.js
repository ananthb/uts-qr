import * as aesjs from "aes-js";

export async function onRequestPost({ request, env }) {
	const data = await request.text();

	if (!data) {
		return new Response("missing data", {
			status: 400,
		});
	}

	const text = decrypt(env.UTS_QR_KEY, data);

	const parts = text.split(":");
	if (parts.length !== 4) {
		return new Response("invalid data", {
			status: 400,
		});
	}

	return new Response(JSON.stringify({
		"name": parts[0],
		"code": parts[1],
		"latitude": parts[2],
		"longitude": parts[3],
	}), { headers: { "Content-Type": "application/json" } });
}

/**
 *
 * Decrypt base64 strings encrypted using AES-128 ECB and PKCS7 padding.
 *
 * @param {string} key The key to decrypt the string with.
 * @param {string} input The string to decrypt
 * @returns {string} The decrypted string
 */
function decrypt(key, input) {
	const data = input.trim();
	const keyBuffer = aesjs.utils.utf8.toBytes(key.trim());
	const escEcb = new aesjs.ModeOfOperation.ecb(keyBuffer);
	const buf = Buffer.from(data, 'base64');
	const decryptedBytes = escEcb.decrypt(buf);
	const decryptedText = aesjs.utils.utf8.fromBytes(decryptedBytes);

	const regex = /[\u{0001}-\u{0010}]/gu;

	const result = regex.test(decryptedText) ? decryptedText.replace(/[\u{0001}-\u{0010}]/gu, "") : decryptedText;
	return result.trim();
}
