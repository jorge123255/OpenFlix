package com.openflix.presentation.screens.livetv

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Divider
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.domain.model.ChannelGroup
import com.openflix.domain.model.ChannelGroupMember
import com.openflix.domain.model.DuplicateGroup
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun ChannelGroupsScreen(
    onBack: () -> Unit,
    onPlayGroup: (Int) -> Unit = {},
    viewModel: ChannelGroupsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showCreateDialog by remember { mutableStateOf(false) }
    var editingGroup by remember { mutableStateOf<ChannelGroup?>(null) }
    var expandedGroupId by remember { mutableStateOf<Int?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Button(onClick = onBack) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                }
                Text(
                    text = "Channel Groups",
                    style = MaterialTheme.typography.displaySmall,
                    color = OpenFlixColors.OnSurface
                )
            }

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Button(
                    onClick = { viewModel.autoDetectDuplicates() },
                    enabled = !uiState.isDetecting
                ) {
                    if (uiState.isDetecting) {
                        Text("Detecting...")
                    } else {
                        Text("Auto-Detect")
                    }
                }
                Button(onClick = { showCreateDialog = true }) {
                    Icon(Icons.Default.Add, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("New Group")
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Content
        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Loading channel groups...", color = OpenFlixColors.TextSecondary)
                }
            }
            uiState.error != null -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(uiState.error!!, color = OpenFlixColors.Error)
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = {
                            viewModel.clearError()
                            viewModel.loadChannelGroups()
                        }) {
                            Text("Retry")
                        }
                    }
                }
            }
            uiState.groups.isEmpty() -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            "No Channel Groups",
                            style = MaterialTheme.typography.headlineMedium,
                            color = OpenFlixColors.OnSurface
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            "Create groups to combine duplicate channels with automatic failover",
                            color = OpenFlixColors.TextSecondary
                        )
                        Spacer(modifier = Modifier.height(24.dp))
                        Button(onClick = { viewModel.autoDetectDuplicates() }) {
                            Text("Auto-Detect Duplicates")
                        }
                    }
                }
            }
            else -> {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(uiState.groups, key = { it.id }) { group ->
                        ChannelGroupCard(
                            group = group,
                            isExpanded = expandedGroupId == group.id,
                            availableChannels = uiState.availableChannels,
                            onToggleExpand = {
                                expandedGroupId = if (expandedGroupId == group.id) null else group.id
                            },
                            onEdit = { editingGroup = group },
                            onDelete = { viewModel.deleteGroup(group.id) },
                            onPlay = { onPlayGroup(group.id) },
                            onAddChannel = { channelId ->
                                val priority = group.members.size
                                viewModel.addChannelToGroup(group.id, channelId, priority)
                            },
                            onRemoveChannel = { channelId ->
                                viewModel.removeChannelFromGroup(group.id, channelId)
                            },
                            onMoveMemberUp = { member ->
                                viewModel.moveMemberUp(group.id, member.channelId, member.priority)
                            },
                            onMoveMemberDown = { member ->
                                viewModel.moveMemberDown(group.id, member.channelId, member.priority)
                            }
                        )
                    }
                }
            }
        }
    }

    // Create Dialog
    if (showCreateDialog) {
        CreateGroupDialog(
            onDismiss = { showCreateDialog = false },
            onCreate = { name, number, logo ->
                viewModel.createGroup(name, number, logo)
                showCreateDialog = false
            }
        )
    }

    // Edit Dialog
    editingGroup?.let { group ->
        EditGroupDialog(
            group = group,
            onDismiss = { editingGroup = null },
            onSave = { name, number, logo, enabled ->
                viewModel.updateGroup(
                    groupId = group.id,
                    name = name,
                    displayNumber = number,
                    logo = logo,
                    enabled = enabled
                )
                editingGroup = null
            }
        )
    }

    // Auto-Detect Duplicates Dialog
    if (uiState.showDuplicatesDialog) {
        AutoDetectDialog(
            duplicates = uiState.detectedDuplicates,
            onDismiss = { viewModel.dismissDuplicatesDialog() },
            onCreateGroup = { duplicate ->
                viewModel.createGroupFromDuplicate(duplicate)
            }
        )
    }
}

@Composable
private fun ChannelGroupCard(
    group: ChannelGroup,
    isExpanded: Boolean,
    availableChannels: List<Channel>,
    onToggleExpand: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    onPlay: () -> Unit,
    onAddChannel: (Int) -> Unit,
    onRemoveChannel: (Int) -> Unit,
    onMoveMemberUp: (ChannelGroupMember) -> Unit,
    onMoveMemberDown: (ChannelGroupMember) -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    var showAddChannel by remember { mutableStateOf(false) }
    var showDeleteConfirm by remember { mutableStateOf(false) }

    Surface(
        onClick = onToggleExpand,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) {
                    Modifier.border(
                        BorderStroke(2.dp, OpenFlixColors.Primary),
                        MaterialTheme.shapes.medium
                    )
                } else {
                    Modifier
                }
            ),
        shape = ClickableSurfaceDefaults.shape(MaterialTheme.shapes.medium),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1f)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Header Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Logo
                    if (group.logo != null) {
                        AsyncImage(
                            model = group.logo,
                            contentDescription = group.name,
                            modifier = Modifier
                                .size(48.dp)
                                .background(OpenFlixColors.SurfaceVariant, MaterialTheme.shapes.small),
                            contentScale = ContentScale.Fit
                        )
                    } else {
                        Box(
                            modifier = Modifier
                                .size(48.dp)
                                .background(OpenFlixColors.SurfaceVariant, MaterialTheme.shapes.small),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.Default.Tv,
                                contentDescription = null,
                                tint = OpenFlixColors.TextSecondary
                            )
                        }
                    }

                    Column {
                        Text(
                            text = group.displayName,
                            style = MaterialTheme.typography.titleMedium,
                            color = OpenFlixColors.OnSurface
                        )
                        Text(
                            text = "${group.memberCount} source${if (group.memberCount != 1) "s" else ""}",
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.TextSecondary
                        )
                    }

                    if (!group.enabled) {
                        Surface(
                            shape = MaterialTheme.shapes.small,
                            colors = NonInteractiveSurfaceDefaults.colors(
                                containerColor = OpenFlixColors.SurfaceVariant
                            )
                        ) {
                            Text(
                                "Disabled",
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                style = MaterialTheme.typography.labelSmall,
                                color = OpenFlixColors.TextSecondary
                            )
                        }
                    }
                }

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(onClick = onPlay) {
                        Icon(Icons.Default.PlayArrow, contentDescription = "Play")
                    }
                    Button(onClick = onEdit) {
                        Icon(Icons.Default.Edit, contentDescription = "Edit")
                    }
                    Button(onClick = { showDeleteConfirm = true }) {
                        Icon(Icons.Default.Delete, contentDescription = "Delete")
                    }
                    Icon(
                        if (isExpanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                        contentDescription = if (isExpanded) "Collapse" else "Expand",
                        tint = OpenFlixColors.TextSecondary
                    )
                }
            }

            // Expanded Content
            if (isExpanded) {
                Spacer(modifier = Modifier.height(16.dp))
                Divider(color = OpenFlixColors.SurfaceVariant)
                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    "Stream Sources (ordered by priority)",
                    style = MaterialTheme.typography.labelMedium,
                    color = OpenFlixColors.TextSecondary
                )
                Spacer(modifier = Modifier.height(8.dp))

                // Members list
                val sortedMembers = group.sortedMembers
                sortedMembers.forEachIndexed { index, member ->
                    MemberRow(
                        member = member,
                        isFirst = index == 0,
                        isLast = index == sortedMembers.size - 1,
                        onMoveUp = { onMoveMemberUp(member) },
                        onMoveDown = { onMoveMemberDown(member) },
                        onRemove = { onRemoveChannel(member.channelId) }
                    )
                    if (index < sortedMembers.size - 1) {
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))
                Button(onClick = { showAddChannel = true }) {
                    Icon(Icons.Default.Add, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Add Channel")
                }
            }
        }
    }

    // Add Channel Dialog
    if (showAddChannel) {
        AddChannelDialog(
            availableChannels = availableChannels,
            existingChannelIds = group.members.map { it.channelId },
            onDismiss = { showAddChannel = false },
            onSelect = { channel ->
                channel.id.toIntOrNull()?.let { onAddChannel(it) }
                showAddChannel = false
            }
        )
    }

    // Delete Confirmation
    if (showDeleteConfirm) {
        DeleteConfirmDialog(
            groupName = group.name,
            onDismiss = { showDeleteConfirm = false },
            onConfirm = {
                onDelete()
                showDeleteConfirm = false
            }
        )
    }
}

@Composable
private fun MemberRow(
    member: ChannelGroupMember,
    isFirst: Boolean,
    isLast: Boolean,
    onMoveUp: () -> Unit,
    onMoveDown: () -> Unit,
    onRemove: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(OpenFlixColors.SurfaceVariant, MaterialTheme.shapes.small)
            .padding(12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Priority badge
            Surface(
                shape = MaterialTheme.shapes.small,
                colors = NonInteractiveSurfaceDefaults.colors(
                    containerColor = if (member.isPrimary) OpenFlixColors.Primary else OpenFlixColors.Surface
                )
            ) {
                Text(
                    "${member.priority + 1}",
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                    style = MaterialTheme.typography.labelMedium,
                    color = if (member.isPrimary) OpenFlixColors.OnPrimary else OpenFlixColors.OnSurface
                )
            }

            // Channel info
            member.channel?.let { channel ->
                if (channel.logo != null) {
                    AsyncImage(
                        model = channel.logo,
                        contentDescription = channel.name,
                        modifier = Modifier.size(32.dp),
                        contentScale = ContentScale.Fit
                    )
                }
                Column {
                    Text(
                        text = channel.name,
                        style = MaterialTheme.typography.bodyMedium,
                        color = OpenFlixColors.OnSurface
                    )
                    channel.sourceName?.let { source ->
                        Text(
                            text = source,
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.TextSecondary
                        )
                    }
                }
            } ?: Text(
                "Channel #${member.channelId}",
                style = MaterialTheme.typography.bodyMedium,
                color = OpenFlixColors.OnSurface
            )
        }

        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Button(
                onClick = onMoveUp,
                enabled = !isFirst
            ) {
                Icon(Icons.Default.KeyboardArrowUp, contentDescription = "Move up")
            }
            Button(
                onClick = onMoveDown,
                enabled = !isLast
            ) {
                Icon(Icons.Default.KeyboardArrowDown, contentDescription = "Move down")
            }
            Button(onClick = onRemove) {
                Icon(Icons.Default.Close, contentDescription = "Remove")
            }
        }
    }
}

@Composable
private fun CreateGroupDialog(
    onDismiss: () -> Unit,
    onCreate: (name: String, number: Int, logo: String?) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var number by remember { mutableStateOf("") }
    var logo by remember { mutableStateOf("") }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = MaterialTheme.shapes.large,
            colors = NonInteractiveSurfaceDefaults.colors(containerColor = OpenFlixColors.Surface)
        ) {
            Column(modifier = Modifier.padding(24.dp)) {
                Text(
                    "Create Channel Group",
                    style = MaterialTheme.typography.headlineSmall,
                    color = OpenFlixColors.OnSurface
                )
                Spacer(modifier = Modifier.height(24.dp))

                OutlinedTextField(
                    value = name,
                    onValueChange = { value -> name = value },
                    label = { Text("Group Name") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(16.dp))

                OutlinedTextField(
                    value = number,
                    onValueChange = { value -> number = value.filter { c -> c.isDigit() } },
                    label = { Text("Channel Number") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(16.dp))

                OutlinedTextField(
                    value = logo,
                    onValueChange = { value -> logo = value },
                    label = { Text("Logo URL (optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )

                Spacer(modifier = Modifier.height(24.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Button(onClick = onDismiss) {
                        Text("Cancel")
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Button(
                        onClick = {
                            val num = number.toIntOrNull() ?: 0
                            onCreate(name, num, logo.ifBlank { null })
                        },
                        enabled = name.isNotBlank()
                    ) {
                        Text("Create")
                    }
                }
            }
        }
    }
}

@Composable
private fun EditGroupDialog(
    group: ChannelGroup,
    onDismiss: () -> Unit,
    onSave: (name: String, number: Int, logo: String?, enabled: Boolean) -> Unit
) {
    var name by remember { mutableStateOf(group.name) }
    var number by remember { mutableStateOf(group.displayNumber.toString()) }
    var logo by remember { mutableStateOf(group.logo ?: "") }
    var enabled by remember { mutableStateOf(group.enabled) }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = MaterialTheme.shapes.large,
            colors = NonInteractiveSurfaceDefaults.colors(containerColor = OpenFlixColors.Surface)
        ) {
            Column(modifier = Modifier.padding(24.dp)) {
                Text(
                    "Edit Channel Group",
                    style = MaterialTheme.typography.headlineSmall,
                    color = OpenFlixColors.OnSurface
                )
                Spacer(modifier = Modifier.height(24.dp))

                OutlinedTextField(
                    value = name,
                    onValueChange = { value -> name = value },
                    label = { Text("Group Name") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(16.dp))

                OutlinedTextField(
                    value = number,
                    onValueChange = { value -> number = value.filter { c -> c.isDigit() } },
                    label = { Text("Channel Number") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(16.dp))

                OutlinedTextField(
                    value = logo,
                    onValueChange = { value -> logo = value },
                    label = { Text("Logo URL (optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(16.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Switch(
                        checked = enabled,
                        onCheckedChange = { enabled = it }
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Enabled", color = OpenFlixColors.OnSurface)
                }

                Spacer(modifier = Modifier.height(24.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Button(onClick = onDismiss) {
                        Text("Cancel")
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Button(
                        onClick = {
                            val num = number.toIntOrNull() ?: 0
                            onSave(name, num, logo.ifBlank { null }, enabled)
                        },
                        enabled = name.isNotBlank()
                    ) {
                        Text("Save")
                    }
                }
            }
        }
    }
}

@Composable
private fun AddChannelDialog(
    availableChannels: List<Channel>,
    existingChannelIds: List<Int>,
    onDismiss: () -> Unit,
    onSelect: (Channel) -> Unit
) {
    var searchQuery by remember { mutableStateOf("") }

    val filteredChannels = remember(searchQuery, availableChannels, existingChannelIds) {
        availableChannels
            .filter { channel ->
                val channelIdInt = channel.id.toIntOrNull()
                channelIdInt != null && channelIdInt !in existingChannelIds
            }
            .filter { channel ->
                searchQuery.isBlank() ||
                        channel.name.contains(searchQuery, ignoreCase = true) ||
                        channel.number?.contains(searchQuery) == true
            }
    }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = MaterialTheme.shapes.large,
            colors = NonInteractiveSurfaceDefaults.colors(containerColor = OpenFlixColors.Surface),
            modifier = Modifier.heightIn(max = 500.dp)
        ) {
            Column(modifier = Modifier.padding(24.dp)) {
                Text(
                    "Add Channel to Group",
                    style = MaterialTheme.typography.headlineSmall,
                    color = OpenFlixColors.OnSurface
                )
                Spacer(modifier = Modifier.height(16.dp))

                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { value -> searchQuery = value },
                    label = { Text("Search channels") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) }
                )
                Spacer(modifier = Modifier.height(16.dp))

                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(filteredChannels.take(50)) { channel ->
                        ChannelSelectItem(
                            channel = channel,
                            onClick = { onSelect(channel) }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.align(Alignment.End)
                ) {
                    Text("Cancel")
                }
            }
        }
    }
}

@Composable
private fun ChannelSelectItem(
    channel: Channel,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(MaterialTheme.shapes.small),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.SurfaceVariant,
            focusedContainerColor = OpenFlixColors.FocusBackground
        )
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            if (channel.logo != null) {
                AsyncImage(
                    model = channel.logo,
                    contentDescription = channel.name,
                    modifier = Modifier.size(32.dp),
                    contentScale = ContentScale.Fit
                )
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = channel.displayName,
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.OnSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                channel.sourceName?.let { source ->
                    Text(
                        text = source,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary
                    )
                }
            }
        }
    }
}

@Composable
private fun DeleteConfirmDialog(
    groupName: String,
    onDismiss: () -> Unit,
    onConfirm: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = MaterialTheme.shapes.large,
            colors = NonInteractiveSurfaceDefaults.colors(containerColor = OpenFlixColors.Surface)
        ) {
            Column(modifier = Modifier.padding(24.dp)) {
                Text(
                    "Delete Group?",
                    style = MaterialTheme.typography.headlineSmall,
                    color = OpenFlixColors.OnSurface
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    "Are you sure you want to delete \"$groupName\"? This will not delete the underlying channels.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.TextSecondary
                )
                Spacer(modifier = Modifier.height(24.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    Button(onClick = onDismiss) {
                        Text("Cancel")
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Button(onClick = onConfirm) {
                        Text("Delete")
                    }
                }
            }
        }
    }
}

@Composable
private fun AutoDetectDialog(
    duplicates: List<DuplicateGroup>,
    onDismiss: () -> Unit,
    onCreateGroup: (DuplicateGroup) -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = MaterialTheme.shapes.large,
            colors = NonInteractiveSurfaceDefaults.colors(containerColor = OpenFlixColors.Surface),
            modifier = Modifier.heightIn(max = 600.dp)
        ) {
            Column(modifier = Modifier.padding(24.dp)) {
                Text(
                    "Detected Duplicates",
                    style = MaterialTheme.typography.headlineSmall,
                    color = OpenFlixColors.OnSurface
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    "Found ${duplicates.size} channel${if (duplicates.size != 1) "s" else ""} with duplicate sources",
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.TextSecondary
                )
                Spacer(modifier = Modifier.height(16.dp))

                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(duplicates) { duplicate ->
                        DuplicateGroupItem(
                            duplicate = duplicate,
                            onCreateGroup = { onCreateGroup(duplicate) }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.align(Alignment.End)
                ) {
                    Text("Done")
                }
            }
        }
    }
}

@Composable
private fun DuplicateGroupItem(
    duplicate: DuplicateGroup,
    onCreateGroup: () -> Unit
) {
    Surface(
        shape = MaterialTheme.shapes.medium,
        colors = NonInteractiveSurfaceDefaults.colors(containerColor = OpenFlixColors.SurfaceVariant)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = duplicate.name,
                        style = MaterialTheme.typography.titleMedium,
                        color = OpenFlixColors.OnSurface
                    )
                    Text(
                        text = "${duplicate.channels.size} sources",
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary
                    )
                }
                Button(onClick = onCreateGroup) {
                    Text("Create Group")
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            duplicate.channels.take(3).forEach { channel ->
                Row(
                    modifier = Modifier.padding(vertical = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        "\u2022",
                        color = OpenFlixColors.TextSecondary
                    )
                    Text(
                        text = channel.providerName,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary
                    )
                }
            }
            if (duplicate.channels.size > 3) {
                Text(
                    "+ ${duplicate.channels.size - 3} more",
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextSecondary,
                    modifier = Modifier.padding(start = 16.dp)
                )
            }
        }
    }
}
