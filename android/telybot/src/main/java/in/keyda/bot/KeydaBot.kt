package `in`.keyda.bot

import android.app.Activity
import android.content.Context
import android.util.AttributeSet
import com.telybot.sdk.TelyBot
import com.telybot.sdk.TelyBotView

/**
 * The 0.x name of [TelyBot], kept for one major so an app updates the dependency first and the
 * code after. Every member forwards to [TelyBot]; nothing here has state of its own.
 * Removed in 2.0.0.
 */
@Deprecated(
    "Renamed: use com.telybot.sdk.TelyBot",
    ReplaceWith("TelyBot", "com.telybot.sdk.TelyBot"),
)
object KeydaBot {
    const val DEFAULT_BASE_URL = TelyBot.DEFAULT_BASE_URL

    /** The 0.x name of [TelyBot.Listener]. An implementation of this one is a [TelyBot.Listener]. */
    @Deprecated("Renamed: use com.telybot.sdk.TelyBot.Listener", ReplaceWith("TelyBot.Listener", "com.telybot.sdk.TelyBot"))
    interface Listener : TelyBot.Listener

    @JvmStatic
    var listener: TelyBot.Listener?
        get() = TelyBot.listener
        set(value) { TelyBot.listener = value }

    @JvmStatic
    val isShowing: Boolean get() = TelyBot.isShowing

    @JvmStatic
    val hasUnreadReply: Boolean get() = TelyBot.hasUnreadReply

    @JvmStatic
    fun checkForReplies() = TelyBot.checkForReplies()

    @JvmStatic
    @JvmOverloads
    fun setVisitor(name: String? = null, phone: String? = null, email: String? = null) =
        TelyBot.setVisitor(name, phone, email)

    @JvmStatic
    fun clearVisitor() = TelyBot.clearVisitor()

    @JvmStatic
    @JvmOverloads
    fun init(context: Context, clientId: String, baseUrl: String = TelyBot.DEFAULT_BASE_URL) =
        TelyBot.init(context, clientId, baseUrl)

    @JvmStatic
    @JvmOverloads
    fun show(activity: Activity, question: String? = null) = TelyBot.show(activity, question)

    @JvmStatic
    fun dismiss() = TelyBot.dismiss()
}

/** The 0.x name of [TelyBotView]. Removed in 2.0.0. */
@Deprecated("Renamed: use com.telybot.sdk.TelyBotView", ReplaceWith("TelyBotView", "com.telybot.sdk.TelyBotView"))
class KeydaBotView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
) : TelyBotView(context, attrs, defStyleAttr)
