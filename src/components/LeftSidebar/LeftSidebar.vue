<!--
  - @copyright Copyright (c) 2019 Marco Ambrosini <marcoambrosini@icloud.com>
  -
  - @author Marco Ambrosini <marcoambrosini@icloud.com>
  -
  - @license GNU AGPL version 3 or any later version
  -
  - This program is free software: you can redistribute it and/or modify
  - it under the terms of the GNU Affero General Public License as
  - published by the Free Software Foundation, either version 3 of the
  - License, or (at your option) any later version.
  -
  - This program is distributed in the hope that it will be useful,
  - but WITHOUT ANY WARRANTY; without even the implied warranty of
  - MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  - GNU Affero General Public License for more details.
  -
  - You should have received a copy of the GNU Affero General Public License
  - along with this program. If not, see <http://www.gnu.org/licenses/>.
-->

<template>
	<NcAppNavigation ref="leftSidebar" :aria-label="t('spreed', 'Conversation list')">
		<div class="new-conversation"
			:class="{ 'new-conversation--scrolled-down': !isScrolledToTop }">
			<div class="conversations-search"
				:class="{'conversations-search--expanded': isFocused}">
				<SearchBox ref="searchBox"
					:value.sync="searchText"
					:is-focused.sync="isFocused"
					@input="debounceFetchSearchResults"
					@abort-search="abortSearch" />
			</div>

			<TransitionWrapper name="radial-reveal">
				<!-- Filters -->
				<NcActions v-show="searchText === ''"
					:primary="isFiltered !== null"
					class="filters"
					:class="{'hidden-visually': isFocused}">
					<template #icon>
						<FilterIcon :size="15" />
					</template>
					<NcActionButton close-after-click
						class="filter-actions__button"
						:class="{'filter-actions__button--active': isFiltered === 'mentions'}"
						@click="handleFilter('mentions')">
						<template #icon>
							<AtIcon :size="20" />
						</template>
						{{ t('spreed','Filter unread mentions') }}
					</NcActionButton>

					<NcActionButton close-after-click
						class="filter-actions__button"
						:class="{'filter-actions__button--active': isFiltered === 'unread'}"
						@click="handleFilter('unread')">
						<template #icon>
							<MessageBadge :size="20" />
						</template>
						{{ t('spreed','Filter unread messages') }}
					</NcActionButton>

					<NcActionButton v-if="isFiltered"
						close-after-click
						class="filter-actions__clearbutton"
						@click="handleFilter(null)">
						<template #icon>
							<FilterRemoveIcon :size="20" />
						</template>
						{{ t('spreed', 'Clear filters') }}
					</NcActionButton>
				</NcActions>
			</TransitionWrapper>

			<!-- Actions -->
			<TransitionWrapper name="radial-reveal">
				<NcActions v-show="searchText === ''"
					class="actions"
					:class="{'hidden-visually': isFocused}">
					<template #icon>
						<DotsVertical :size="20" />
					</template>
					<NcActionButton v-if="canStartConversations"
						close-after-click
						@click="showModalNewConversation">
						<template #icon>
							<Plus :size="20" />
						</template>
						{{ t('spreed','Create a new conversation') }}
					</NcActionButton>

					<NcActionButton close-after-click
						@click="showModalListConversations">
						<template #icon>
							<List :size="20" />
						</template>
						{{ t('spreed','Join open conversations') }}
					</NcActionButton>
				</NcActions>
			</TransitionWrapper>

			<!-- All open conversations list -->
			<OpenConversationsList ref="openConversationsList" />

			<!-- New Conversation dialog-->
			<NewGroupConversation ref="newGroupConversation" />
		</div>

		<template #list>
			<li ref="container" class="left-sidebar__list">
				<ul class="scroller h-100">
					<!-- Conversations List -->
					<template v-if="!isSearching">
						<li class="h-100">
							<ConversationsListVirtual ref="scroller"
								:conversations="filteredConversationsList"
								:loading="!initialisedConversations"
								class="h-100"
								@scroll.native="debounceHandleScroll" />
						</li>
						<Hint v-if="initialisedConversations && filteredConversationsList.length === 0" :hint="t('spreed', 'No matches found')" />

						<NcButton v-if="!preventFindingUnread && lastUnreadMentionBelowViewportIndex !== null"
							class="unread-mention-button"
							type="primary"
							@click="scrollBottomUnread">
							{{ t('spreed', 'Unread mentions') }}
						</NcButton>
					</template>

					<!-- Search results -->
					<template v-else-if="isSearching">
						<!-- Create a new conversation -->
						<NcListItem v-if="searchResultsConversationList.length === 0 && canStartConversations"
							:title="t('spreed', 'Create a new conversation')"
							@click="createConversation(searchText)">
							<template #icon>
								<ChatPlus :size="30" />
							</template>
							<template #subtitle>
								{{ searchText }}
							</template>
						</NcListItem>

						<!-- Search results: user's conversations -->
						<NcAppNavigationCaption :title="t('spreed', 'Conversations')" />
						<Conversation v-for="item of searchResultsConversationList"
							:key="`conversation_${item.id}`"
							:ref="`conversation-${item.token}`"
							:item="item"
							@click="abortSearch" />
						<Hint v-if="searchResultsConversationList.length === 0" :hint="t('spreed', 'No matches found')" />

						<!-- Search results: listed (open) conversations -->
						<template v-if="!listedConversationsLoading && searchResultsListedConversations.length !== 0">
							<NcAppNavigationCaption :title="t('spreed', 'Open conversations')" />
							<Conversation v-for="item of searchResultsListedConversations"
								:key="`open-conversation_${item.id}`"
								:item="item"
								is-search-result
								@click="abortSearch" />
						</template>

						<!-- Search results: users -->
						<template v-if="searchResultsUsers.length !== 0">
							<NcAppNavigationCaption :title="t('spreed', 'Users')" />
							<NcListItem v-for="item of searchResultsUsers"
								:key="`user_${item.id}`"
								:title="item.label"
								@click="createAndJoinConversation(item)">
								<template #icon>
									<ConversationIcon :item="iconData(item)" disable-menu />
								</template>
							</NcListItem>
						</template>

						<!-- Search results: new conversations -->
						<template v-if="canStartConversations">
							<!-- New conversations: Groups -->
							<template v-if="searchResultsGroups.length !== 0">
								<NcAppNavigationCaption :title="t('spreed', 'Groups')" />
								<NcListItem v-for="item of searchResultsGroups"
									:key="`group_${item.id}`"
									:title="item.label"
									@click="createAndJoinConversation(item)">
									<template #icon>
										<ConversationIcon :item="iconData(item)" disable-menu />
									</template>
								</NcListItem>
							</template>

							<!-- New conversations: Circles -->
							<template v-if="searchResultsCircles.length !== 0">
								<NcAppNavigationCaption :title="t('spreed', 'Circles')" />
								<NcListItem v-for="item of searchResultsCircles"
									:key="`circle_${item.id}`"
									:title="item.label"
									@click="createAndJoinConversation(item)">
									<template #icon>
										<ConversationIcon :item="iconData(item)" disable-menu />
									</template>
								</NcListItem>
							</template>
						</template>

						<!-- Search results: no results (yet) -->
						<NcAppNavigationCaption v-if="sourcesWithoutResults" :title="sourcesWithoutResultsList" />
						<Hint v-if="contactsLoading" :hint="t('spreed', 'Loading')" />
						<Hint v-else :hint="t('spreed', 'No search results')" />
					</template>
				</ul>
			</li>
		</template>

		<template #footer>
			<div id="app-settings">
				<div id="app-settings-header">
					<NcButton class="settings-button" @click="showSettings">
						{{ t('spreed', 'Talk settings') }}
					</NcButton>
				</div>
			</div>
		</template>
	</NcAppNavigation>
</template>

<script>
import debounce from 'debounce'
import { ref } from 'vue'

import AtIcon from 'vue-material-design-icons/At.vue'
import ChatPlus from 'vue-material-design-icons/ChatPlus.vue'
import DotsVertical from 'vue-material-design-icons/DotsVertical.vue'
import FilterIcon from 'vue-material-design-icons/Filter.vue'
import FilterRemoveIcon from 'vue-material-design-icons/FilterRemove.vue'
import List from 'vue-material-design-icons/FormatListBulleted.vue'
import MessageBadge from 'vue-material-design-icons/MessageBadge.vue'
import Plus from 'vue-material-design-icons/Plus.vue'

import { showError } from '@nextcloud/dialogs'
import { emit } from '@nextcloud/event-bus'
import { loadState } from '@nextcloud/initial-state'

import NcActionButton from '@nextcloud/vue/dist/Components/NcActionButton.js'
import NcActions from '@nextcloud/vue/dist/Components/NcActions.js'
import NcAppNavigation from '@nextcloud/vue/dist/Components/NcAppNavigation.js'
import NcAppNavigationCaption from '@nextcloud/vue/dist/Components/NcAppNavigationCaption.js'
import NcButton from '@nextcloud/vue/dist/Components/NcButton.js'
import NcListItem from '@nextcloud/vue/dist/Components/NcListItem.js'
import isMobile from '@nextcloud/vue/dist/Mixins/isMobile.js'

import ConversationIcon from '../ConversationIcon.vue'
import Hint from '../Hint.vue'
import TransitionWrapper from '../TransitionWrapper.vue'
import Conversation from './ConversationsList/Conversation.vue'
import ConversationsListVirtual from './ConversationsListVirtual.vue'
import NewGroupConversation from './NewGroupConversation/NewGroupConversation.vue'
import OpenConversationsList from './OpenConversationsList/OpenConversationsList.vue'
import SearchBox from './SearchBox/SearchBox.vue'

import { useArrowNavigation } from '../../composables/useArrowNavigation.js'
import { CONVERSATION } from '../../constants.js'
import {
	createPrivateConversation,
	searchPossibleConversations,
	searchListedConversations,
} from '../../services/conversationsService.js'
import { EventBus } from '../../services/EventBus.js'
import { talkBroadcastChannel } from '../../services/talkBroadcastChannel.js'
import CancelableRequest from '../../utils/cancelableRequest.js'
import { requestTabLeadership } from '../../utils/requestTabLeadership.js'

export default {

	name: 'LeftSidebar',

	components: {
		NcAppNavigation,
		NcAppNavigationCaption,
		NcButton,
		Hint,
		SearchBox,
		NewGroupConversation,
		OpenConversationsList,
		Conversation,
		NcListItem,
		ConversationIcon,
		NcActions,
		NcActionButton,
		TransitionWrapper,
		ConversationsListVirtual,
		// Icons
		AtIcon,
		MessageBadge,
		FilterIcon,
		FilterRemoveIcon,
		Plus,
		ChatPlus,
		List,
		DotsVertical,
	},

	mixins: [
		isMobile,
	],

	setup() {
		const leftSidebar = ref(null)
		const searchBox = ref(null)

		const { initializeNavigation } = useArrowNavigation(leftSidebar, searchBox)

		return {
			initializeNavigation,
			leftSidebar,
			searchBox,
		}
	},

	data() {
		return {
			searchText: '',
			searchResults: [],
			searchResultsUsers: [],
			searchResultsGroups: [],
			searchResultsCircles: [],
			searchResultsListedConversations: [],
			contactsLoading: false,
			listedConversationsLoading: false,
			isCirclesEnabled: loadState('spreed', 'circles_enabled'),
			canStartConversations: loadState('spreed', 'start_conversations'),
			initialisedConversations: false,
			cancelSearchPossibleConversations: () => {},
			cancelSearchListedConversations: () => {},
			// Keeps track of whether the conversation list is scrolled to the top or not
			isScrolledToTop: true,
			refreshTimer: null,
			/**
			 * @type {number|null}
			 */
			lastUnreadMentionBelowViewportIndex: null,
			preventFindingUnread: false,
			roomListModifiedBefore: 0,
			forceFullRoomListRefreshAfterXLoops: 0,
			isFetchingConversations: false,
			isCurrentTabLeader: false,
			isFocused: false,
			isFiltered: null,
		}
	},

	computed: {
		conversationsList() {
			return this.$store.getters.conversationsList
		},

		searchResultsConversationList() {
			if (this.searchText !== '' || this.isFocused) {
				const lowerSearchText = this.searchText.toLowerCase()
				return this.conversationsList.filter(conversation =>
					conversation.displayName.toLowerCase().includes(lowerSearchText)
					|| conversation.name.toLowerCase().includes(lowerSearchText)
				)
			} else {
				return []
			}
		},

		filteredConversationsList() {
			if (this.isFocused) {
				return this.conversationsList
			}

			if (this.isFiltered === 'unread') {
				return this.conversationsList.filter(conversation => conversation.unreadMessages > 0 || conversation.hasCall)
			}

			if (this.isFiltered === 'mentions') {
				return this.conversationsList.filter(conversation => conversation.unreadMention
				|| conversation.hasCall
				|| (conversation.unreadMessages > 0 && (conversation.type === CONVERSATION.TYPE.ONE_TO_ONE || conversation.type === CONVERSATION.TYPE.ONE_TO_ONE_FORMER)))
			}

			return this.conversationsList
		},

		isSearching() {
			return this.searchText !== ''
		},

		sourcesWithoutResults() {
			return !this.searchResultsUsers.length
				|| !this.searchResultsGroups.length
				|| (this.isCirclesEnabled && !this.searchResultsCircles.length)
		},

		sourcesWithoutResultsList() {
			const hasNoResultsUsers = !this.searchResultsUsers.length
			const hasNoResultsGroups = !this.searchResultsGroups.length
			const hasNoResultsCircles = this.isCirclesEnabled && !this.searchResultsCircles.length

			if (hasNoResultsUsers) {
				if (hasNoResultsGroups) {
					return (hasNoResultsCircles)
						? t('spreed', 'Users, groups and circles')
						: t('spreed', 'Users and groups')
				} else {
					return (hasNoResultsCircles)
						? t('spreed', 'Users and circles')
						: t('spreed', 'Users')
				}
			} else {
				if (hasNoResultsGroups) {
					return (hasNoResultsCircles)
						? t('spreed', 'Groups and circles')
						: t('spreed', 'Groups')
				} else {
					return (hasNoResultsCircles)
						? t('spreed', 'Circles')
						: t('spreed', 'Other sources')
				}
			}
		},
	},

	beforeMount() {
		// Restore last fetched conversations from browser storage,
		// before updated ones come from server
		this.restoreConversations()

		requestTabLeadership().then(() => {
			this.isCurrentTabLeader = true
			this.fetchConversations()
			// Refreshes the conversations list every 30 seconds
			this.refreshTimer = window.setInterval(() => {
				this.fetchConversations()
			}, 30000)
		})

		talkBroadcastChannel.addEventListener('message', (event) => {
			if (this.isCurrentTabLeader) {
				switch (event.data.message) {
				case 'force-fetch-all-conversations':
					this.roomListModifiedBefore = 0
					this.forceFullRoomListRefreshAfterXLoops = 10
					this.debounceFetchConversations()
					break
				}
			} else {
				switch (event.data.message) {
				case 'update-conversations':
					this.$store.dispatch('patchConversations', {
						conversations: event.data.conversations,
						withRemoving: event.data.withRemoving,
					})
					break
				case 'update-nextcloud-talk-hash':
					this.$store.dispatch('setNextcloudTalkHash', event.data.hash)
					break
				}
			}
		})
	},

	mounted() {
		EventBus.$on('should-refresh-conversations', this.handleShouldRefreshConversations)
		EventBus.$once('conversations-received', this.handleConversationsReceived)
		EventBus.$on('route-change', this.onRouteChange)
	},

	beforeDestroy() {
		EventBus.$off('should-refresh-conversations', this.handleShouldRefreshConversations)
		EventBus.$off('conversations-received', this.handleUnreadMention)
		EventBus.$off('route-change', this.onRouteChange)

		this.cancelSearchPossibleConversations()
		this.cancelSearchPossibleConversations = null

		this.cancelSearchListedConversations()
		this.cancelSearchListedConversations = null

		if (this.refreshTimer) {
			clearInterval(this.refreshTimer)
			this.refreshTimer = null
		}
	},

	methods: {
		showModalNewConversation() {
			this.$refs.newGroupConversation.showModal()
		},

		showModalListConversations() {
			this.$refs.openConversationsList.showModal()
		},

		handleFilter(filter) {
			this.isFiltered = filter
			// Clear the search input once a filter is active
			this.searchText = ''
		},

		scrollBottomUnread() {
			this.preventFindingUnread = true
			this.$refs.scroller.scrollToItem(this.lastUnreadMentionBelowViewportIndex)
			setTimeout(() => {
				this.handleUnreadMention()
				this.preventFindingUnread = false
			}, 500)
		},
		debounceFetchSearchResults: debounce(function() {
			if (this.isSearching) {
				this.fetchSearchResults()
			}
		}, 250),

		async fetchPossibleConversations() {
			this.contactsLoading = true

			try {
				// FIXME: move to conversationsStore
				this.cancelSearchPossibleConversations('canceled')
				const { request, cancel } = CancelableRequest(searchPossibleConversations)
				this.cancelSearchPossibleConversations = cancel

				const response = await request({
					searchText: this.searchText,
					token: undefined,
					onlyUsers: !this.canStartConversations,
				})

				this.searchResults = response?.data?.ocs?.data || []
				this.searchResultsUsers = this.searchResults.filter((match) => {
					return match.source === 'users'
						&& match.id !== this.$store.getters.getUserId()
						&& !this.hasOneToOneConversationWith(match.id)
				})
				this.searchResultsGroups = this.searchResults.filter((match) => match.source === 'groups')
				this.searchResultsCircles = this.searchResults.filter((match) => match.source === 'circles')
				this.contactsLoading = false
				this.$nextTick(() => {
					this.initializeNavigation('.list-item')
				})
			} catch (exception) {
				if (CancelableRequest.isCancel(exception)) {
					return
				}
				console.error('Error searching for possible conversations', exception)
				showError(t('spreed', 'An error occurred while performing the search'))
			}
		},

		async fetchListedConversations() {
			try {
				this.listedConversationsLoading = true

				// FIXME: move to conversationsStore
				this.cancelSearchListedConversations('canceled')
				const { request, cancel } = CancelableRequest(searchListedConversations)
				this.cancelSearchListedConversations = cancel

				const response = await request({ searchText: this.searchText })
				this.searchResultsListedConversations = response.data.ocs.data
				this.listedConversationsLoading = false
				this.$nextTick(() => {
					this.initializeNavigation('.list-item')
				})
			} catch (exception) {
				if (CancelableRequest.isCancel(exception)) {
					return
				}
				console.error('Error searching for open conversations', exception)
				showError(t('spreed', 'An error occurred while performing the search'))
			}
		},

		async fetchSearchResults() {
			await Promise.all([this.fetchPossibleConversations(), this.fetchListedConversations()])
		},

		/**
		 * Create a new conversation with the selected user
		 * or bring up the dialog to create a new group/circle conversation
		 *
		 * @param {object} item The autocomplete suggestion to start a conversation with
		 * @param {string} item.id The ID of the target
		 * @param {string} item.label The displayname of the target
		 * @param {string} item.source The source of the target (e.g. users, groups, circle)
		 */
		async createAndJoinConversation(item) {
			if (item.source === 'users') {
				// Create one-to-one conversation directly
				const conversation = await this.$store.dispatch('createOneToOneConversation', item.id)
				this.abortSearch()
				this.$router.push({
					name: 'conversation',
					params: { token: conversation.token },
				}).catch(err => console.debug(`Error while pushing the new conversation's route: ${err}`))
			} else {
				// For other types, show the modal directly
				this.$refs.newGroupConversation.showModalForItem(item)
			}
		},

		async createConversation(name) {
			const response = await createPrivateConversation(name)
			const conversation = response.data.ocs.data
			this.$store.dispatch('addConversation', conversation)
			this.abortSearch()
			this.$router.push({
				name: 'conversation',
				params: { token: conversation.token },
			}).catch(err => console.debug(`Error while pushing the new conversation's route: ${err}`))
		},

		hasOneToOneConversationWith(userId) {
			return !!this.conversationsList.find(conversation => conversation.type === CONVERSATION.TYPE.ONE_TO_ONE && conversation.name === userId)
		},

		// Reset the search text, therefore end the search operation.
		abortSearch() {
			this.searchText = ''
			this.isFocused = false
			if (this.cancelSearchPossibleConversations) {
				this.cancelSearchPossibleConversations()
			}
			if (this.cancelSearchListedConversations) {
				this.cancelSearchListedConversations()
			}
		},

		showSettings() {
			// FIXME: use local EventBus service instead of the global one
			emit('show-settings')
		},

		/**
		 * @param {object} [options] Options for conversation refreshing
		 * @param {string} [options.token] The conversation token that got update
		 * @param {object} [options.properties] List of changed properties
		 * @param {boolean} [options.all] Whether all conversations should be fetched
		 */
		async handleShouldRefreshConversations(options) {
			if (options?.all === true) {
				if (this.isCurrentTabLeader) {
					this.roomListModifiedBefore = 0
					this.forceFullRoomListRefreshAfterXLoops = 10
				} else {
					// Force leader tab to do a full fetch
					talkBroadcastChannel.postMessage({ message: 'force-fetch-all-conversations' })
					return
				}
			} else if (options?.token && options?.properties) {
				await this.$store.dispatch('setConversationProperties', {
					token: options.token,
					properties: options.properties,
				})
			}

			this.debounceFetchConversations()
		},

		debounceFetchConversations: debounce(function() {
			this.fetchConversations()
		}, 3000),

		async fetchConversations() {
			if (this.isFetchingConversations) {
				return
			}

			this.isFetchingConversations = true
			if (this.forceFullRoomListRefreshAfterXLoops === 0) {
				this.roomListModifiedBefore = 0
				this.forceFullRoomListRefreshAfterXLoops = 10
			} else {
				this.forceFullRoomListRefreshAfterXLoops--
			}

			/**
			 * Fetches the conversations from the server and then adds them one by one
			 * to the store.
			 */
			try {
				const response = await this.$store.dispatch('fetchConversations', {
					modifiedSince: this.roomListModifiedBefore,
				})

				// We can only support this with the HPB as otherwise rooms,
				// you are not currently active in, will not be removed anymore,
				// as there is no signaling message about it when the internal
				// signaling is used.
				if (loadState('spreed', 'signaling_mode') !== 'internal') {
					if (response?.headers && response.headers['x-nextcloud-talk-modified-before']) {
						this.roomListModifiedBefore = response.headers['x-nextcloud-talk-modified-before']
					}
				}

				this.initialisedConversations = true
				/**
				 * Emits a global event that is used in App.vue to update the page title once the
				 * ( if the current route is a conversation and once the conversations are received)
				 */
				EventBus.$emit('conversations-received', { singleConversation: false })
				this.isFetchingConversations = false
			} catch (error) {
				console.debug('Error while fetching conversations: ', error)
				this.isFetchingConversations = false
			}
		},

		async restoreConversations() {
			try {
				await this.$store.dispatch('restoreConversations')
				this.initialisedConversations = true
				EventBus.$emit('conversations-received', { singleConversation: false })
			} catch (error) {
				console.debug('Error while restoring conversations: ', error)
			}
		},

		handleConversationsReceived() {
			this.handleUnreadMention()
			if (this.$route.params.token) {
				this.scrollToConversation(this.$route.params.token)
			}
		},

		// Checks whether the conversations list is scrolled all the way to the top
		// or not
		handleScroll() {
			this.isScrolledToTop = this.$refs.scroller.$el.scrollTop === 0
		},

		/**
		 * Find position of the last unread conversation below viewport
		 */
		async handleUnreadMention() {
			await this.$nextTick()

			this.lastUnreadMentionBelowViewportIndex = null
			const lastConversationInViewport = this.$refs.scroller.getLastItemInViewportIndex()
			for (let i = this.filteredConversationsList.length - 1; i > lastConversationInViewport; i--) {
				if (this.filteredConversationsList[i].unreadMention) {
					this.lastUnreadMentionBelowViewportIndex = i
					return
				}
			}
		},

		debounceHandleScroll: debounce(function() {
			this.handleScroll()
			this.handleUnreadMention()
		}, 50),

		async scrollToConversation(token) {
			await this.$nextTick()

			if (!this.$refs.scroller) {
				return
			}

			this.$refs.scroller.scrollToConversation(token)
		},

		onRouteChange({ from, to }) {
			if (from.name === 'conversation'
				&& to.name === 'conversation'
				&& from.params.token === to.params.token) {
				// this is triggered when the hash in the URL changes
				return
			}
			if (from.name === 'conversation') {
				this.$store.dispatch('leaveConversation', { token: from.params.token })
				if (to.name !== 'conversation') {
					this.$store.dispatch('updateToken', '')
				}
			}
			if (to.name === 'conversation') {
				this.$store.dispatch('joinConversation', { token: to.params.token })
				this.scrollToConversation(to.params.token)
			}
			if (this.isMobile) {
				emit('toggle-navigation', {
					open: false,
				})
			}
		},

		iconData(item) {
			if (item.source === 'users') {
				return {
					type: CONVERSATION.TYPE.ONE_TO_ONE,
					displayName: item.label,
					name: item.id,
				}
			}
			return {
				type: CONVERSATION.TYPE.GROUP,
				objectType: item.source,
			}
		},
	},
}
</script>

<style lang="scss" scoped>
@import '../../assets/variables';

.scroller {
	padding: 0 4px 0 6px;
}

.h-100 {
	height: 100%;
}

.new-conversation {
	position: relative;
	display: flex;
	padding: 8px 4px 8px 12px;
	align-items: center;

	&--scrolled-down {
		border-bottom: 1px solid var(--color-placeholder-dark);
	}

	.filters {
		position: absolute;
		top : 8px;
		right: 56px;
	}

	.actions {
		position: absolute;
		top: 8px;
		right: 8px;
	}
}

// Override vue overflow rules for <ul> elements within app-navigation
.left-sidebar__list {
	height: 100% !important;
	width: 100% !important;
	overflow-y: auto !important;
	overflow-x: hidden !important;
	padding: 0;
}

.unread-mention-button {
	position: absolute !important;
	left: 50%;
	transform: translateX(-50%);
	z-index: 100;
	bottom: 10px;
	white-space: nowrap;
}

.conversations-search {
	padding: 4px 0;
	transition: all 0.15s ease;
	z-index: 1;
	// New conversation button width : 52 px
	// Filters button width : 44 px
	// Spacing : 3px + 1px
	// Total : 100 px
	width : calc(100% - 100px);
	display : flex;
	&--expanded {
		width : calc(100% - 8px);
	}

}

.filter-actions__button--active {
	background-color: var(--color-primary-element-light);
	border-radius: 6px;
	:deep(.action-button__longtext){
		font-weight: bold;
	}

}

.settings-button {
	justify-content: flex-start !important;
}

:deep(.app-navigation ul) {
	padding: 0 !important;
}

:deep(.app-navigation-toggle) {
	top: 8px !important;
	right: -6px !important;
}

:deep(.app-navigation__list) {
	padding: 0 !important;
}

:deep(.list-item:focus, .list-item:focus-visible) {
	z-index: 1;
	outline: 2px solid var(--color-primary-element);
}
</style>
