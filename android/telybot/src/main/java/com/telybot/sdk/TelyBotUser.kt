package com.telybot.sdk

import android.net.Uri
import org.json.JSONObject

/**
 * [TelyBot.setUser]'s token: a JWT as the page itself checks its shape (three base64url parts,
 * at most 2000 characters) before it is sent. Anything else is dropped whole; the server does the
 * real verification.
 */
internal object TelyBotUser {
    private const val MAX = 2000
    private val JWT = Regex("^[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+$")

    fun of(token: String?): String? {
        val t = token?.trim().orEmpty()
        return t.takeIf { it.isNotEmpty() && it.length <= MAX && JWT.matches(it) }
    }

    /** `&user=…` for the URL's #fragment, or nothing. */
    fun fragment(token: String?): String = if (token.isNullOrEmpty()) "" else "&user=" + Uri.encode(token)

    /** The token as a JSON string for `TelyBot.identify` on a page that is already up. */
    fun json(token: String?): String = JSONObject.quote(token.orEmpty())
}
