package com.openflix.domain.model

data class Profile(
    val id: Int,
    val uuid: String,
    val name: String,
    val avatar: String? = null,
    val isKid: Boolean = false,
    val isProtected: Boolean = false,
    val isAdmin: Boolean = false,
    val isGuest: Boolean = false,
    val isRestricted: Boolean = false
) {
    val displayName: String get() = name

    val initials: String get() {
        val parts = name.split(" ")
        return if (parts.size >= 2) {
            "${parts[0].take(1)}${parts[1].take(1)}".uppercase()
        } else {
            name.take(2).uppercase()
        }
    }
}

data class User(
    val id: Int,
    val uuid: String? = null,
    val username: String,
    val email: String? = null,
    val displayName: String? = null,
    val avatar: String? = null,
    val isAdmin: Boolean = false
) {
    val name: String get() = displayName ?: username
}
