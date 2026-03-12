package com.openflix.data.repository

import com.openflix.data.network.OpenFlixApi
import com.openflix.domain.model.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class LiveTVRepository(private val api: OpenFlixApi) {
    private val _channels = MutableStateFlow<List<Channel>>(emptyList())
    val channels: StateFlow<List<Channel>> = _channels.asStateFlow()

    private val _favoriteChannelIds = MutableStateFlow<Set<String>>(emptySet())
    val favoriteChannelIds: StateFlow<Set<String>> = _favoriteChannelIds.asStateFlow()

    suspend fun loadChannels(): List<Channel> {
        val response = api.getChannels()
        val channelList = response.allChannels.map { it.toDomain() }
        _channels.value = channelList
        _favoriteChannelIds.value = channelList.filter { it.isFavorite }.map { it.id }.toSet()
        return channelList
    }

    suspend fun getChannelStream(id: String): String {
        return api.getChannelStream(id).url
    }

    suspend fun toggleFavorite(channelId: String) {
        api.toggleFavorite(channelId)
        val current = _favoriteChannelIds.value.toMutableSet()
        if (current.contains(channelId)) current.remove(channelId) else current.add(channelId)
        _favoriteChannelIds.value = current
    }

    suspend fun loadGuide(startSec: Long? = null, endSec: Long? = null): List<ChannelWithPrograms> {
        val response = api.getGuide(startSec, endSec)
        val programsMap = response.programs ?: emptyMap()

        // Server doesn't include channels in guide response, so use cached channels
        val cachedChannels = _channels.value
        val channelSource = if (cachedChannels.isNotEmpty()) {
            cachedChannels
        } else {
            // Fallback: load channels if not cached yet
            loadChannels()
        }

        return channelSource.mapNotNull { channel ->
            // Match by EPG channelId (e.g. "gracenote-DITV803-10367"), then by numeric id
            val programs = programsMap[channel.channelId]?.map { it.toDomain() }
                ?: programsMap[channel.id]?.map { it.toDomain() }
                ?: emptyList()

            if (programs.isNotEmpty()) {
                ChannelWithPrograms(channel, programs.sortedBy { it.startTimeMs })
            } else {
                // Still include channel even without programs
                ChannelWithPrograms(channel, emptyList())
            }
        }
    }

    suspend fun getNowPlaying(): List<Pair<String, Program>> {
        val response = api.getNowPlaying()
        return response.channels?.mapNotNull { ch ->
            val program = ch.program?.toDomain() ?: return@mapNotNull null
            (ch.channelId ?: "") to program
        } ?: emptyList()
    }

    fun channelsByGroup(group: String?): List<Channel> {
        if (group == null) return _channels.value
        return _channels.value.filter { it.group == group }
    }

    fun channelsSorted(by: ChannelSortOrder = ChannelSortOrder.NUMBER): List<Channel> {
        return when (by) {
            ChannelSortOrder.NUMBER -> _channels.value.sortedBy { it.sortKey }
            ChannelSortOrder.NAME -> _channels.value.sortedBy { it.name.lowercase() }
            ChannelSortOrder.FAVORITES -> _channels.value.sortedByDescending { it.isFavorite }
        }
    }
}

enum class ChannelSortOrder { NUMBER, NAME, FAVORITES }
