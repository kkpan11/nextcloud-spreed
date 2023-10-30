/**
 * @copyright Copyright (c) 2019 Marco Ambrosini <marcoambrosini@icloud.com>
 *
 * @author Marco Ambrosini <marcoambrosini@icloud.com>
 *
 * @license AGPL-3.0-or-later
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

import Hex from 'crypto-js/enc-hex.js'
import SHA256 from 'crypto-js/sha256.js'

import axios from '@nextcloud/axios'
import { generateOcsUrl } from '@nextcloud/router'

/**
 * Fetches messages that belong to a particular conversation
 * specified with its token.
 *
 * @param {object} data the wrapping object;
 * @param {string} data.token the conversation token;
 * @param {string} data.lastKnownMessageId last known message id;
 * @param {boolean} data.includeLastKnown whether to include the last known message in the response;
 * @param {number} [data.limit=100] Number of messages to load
 * @param {object} options options;
 */
const fetchMessages = async function({ token, lastKnownMessageId, includeLastKnown, limit = 100 }, options) {
	return axios.get(generateOcsUrl('apps/spreed/api/v1/chat/{token}', { token }), Object.assign(options, {
		params: {
			setReadMarker: 0,
			lookIntoFuture: 0,
			lastKnownMessageId,
			limit,
			includeLastKnown: includeLastKnown ? 1 : 0,
		},
	}))
}

/**
 * Fetches newly created messages that belong to a particular conversation
 * specified with its token.
 *
 * @param {object} data the wrapping object;
 * @param {number} data.lastKnownMessageId The id of the last message in the store.
 * @param {string} data.token The conversation token;
 * @param {number} [data.limit=100] Number of messages to load
 * @param {object} options options
 */
const lookForNewMessages = async ({ token, lastKnownMessageId, limit = 100 }, options) => {
	return axios.get(generateOcsUrl('apps/spreed/api/v1/chat/{token}', { token }), Object.assign(options, {
		params: {
			setReadMarker: 0,
			lookIntoFuture: 1,
			lastKnownMessageId,
			limit,
			includeLastKnown: 0,
			markNotificationsAsRead: 0,
		},
	}))
}

/**
 * Get the context of a message
 *
 * Loads some messages from before and after the given one.
 *
 * @param {object} data the wrapping object;
 * @param {string} data.token the conversation token;
 * @param {number} data.messageId last known message id;
 * @param {number} [data.limit=50] Number of messages to load
 * @param {object} options options;
 */
const getMessageContext = async function({ token, messageId, limit = 50 }, options) {
	return axios.get(generateOcsUrl('apps/spreed/api/v1/chat/{token}/{messageId}/context', { token, messageId }), Object.assign(options, {
		params: {
			limit,
		},
	}))
}

/**
 * Posts a new message to the server.
 *
 * @param {object} param0 The message object that is destructured
 * @param {string} param0.token The conversation token
 * @param {string} param0.message The message object
 * @param {string} param0.actorDisplayName The display name of the actor
 * @param {string} param0.referenceId A reference id to identify the message later again
 * @param {object|undefined} param0.parent The message to be replied to
 * @param {object} options request options
 * @param {boolean} options.silent whether the message should trigger a notifications for the
 * recipients or not
 */
const postNewMessage = async function({ token, message, actorDisplayName, referenceId, parent }, options) {
	return axios.post(generateOcsUrl('apps/spreed/api/v1/chat/{token}', { token }), {
		message,
		actorDisplayName,
		referenceId,
		replyTo: parent?.id,
		silent: options.silent,
	}, options)
}

/**
 * Deletes a message from the server.
 *
 * @param {object} param0 The message object that is destructured
 * @param {string} param0.token The conversation token
 * @param {string} param0.id The id of the message to be deleted
 */
const deleteMessage = async function({ token, id }) {
	return axios.delete(generateOcsUrl('apps/spreed/api/v1/chat/{token}/{id}', { token, id }))
}

/**
 * Post a rich object to a conversation
 *
 * @param {string} token conversation token
 * @param {object} data the wrapping object;
 * @param {string} data.objectType object type
 * @param {string} data.objectId object id
 * @param {string} data.metaData JSON metadata of the rich object encoded as string
 * @param {string} data.referenceId generated reference id, leave empty to generate it based on the other args
 */
const postRichObjectToConversation = async function(token, { objectType, objectId, metaData, referenceId }) {
	if (!referenceId) {
		const tempId = 'richobject-' + objectType + '-' + objectId + '-' + token + '-' + (new Date().getTime())
		referenceId = Hex.stringify(SHA256(tempId))
	}
	return axios.post(generateOcsUrl('apps/spreed/api/v1/chat/{token}/share', { token }), {
		objectType,
		objectId,
		metaData,
		referenceId,
	})
}

/**
 * Updates the last read message id
 *
 * @param {string} token The token of the conversation to be removed from favorites
 * @param {number} lastReadMessage id of the last read message to set
 */
const updateLastReadMessage = async function(token, lastReadMessage) {
	return axios.post(generateOcsUrl('apps/spreed/api/v1/chat/{token}/read', { token }), {
		lastReadMessage,
	})
}

const addReactionToMessage = async function(token, messageId, selectedEmoji) {
	return axios.post(generateOcsUrl('apps/spreed/api/v1/reaction/{token}/{messageId}', { token, messageId }), {
		reaction: selectedEmoji,
	})
}

const removeReactionFromMessage = async function(token, messageId, selectedEmoji) {
	return axios.delete(generateOcsUrl('apps/spreed/api/v1/reaction/{token}/{messageId}', { token, messageId }), {
		params: {
			reaction: selectedEmoji,
		},
	})
}

const getReactionsDetails = async function(token, messageId) {
	return axios.get(generateOcsUrl('apps/spreed/api/v1/reaction/{token}/{messageId}', { token, messageId }))
}

const getTranslationLanguages = async function() {
	return axios.get(generateOcsUrl('/translation/languages'))
}

const translateText = async function(text, fromLanguage, toLanguage) {
	return axios.post(generateOcsUrl('/translation/translate'), {
		text,
		fromLanguage,
		toLanguage,
	})
}

export {
	fetchMessages,
	lookForNewMessages,
	getMessageContext,
	postNewMessage,
	deleteMessage,
	postRichObjectToConversation,
	updateLastReadMessage,
	addReactionToMessage,
	removeReactionFromMessage,
	getReactionsDetails,
	getTranslationLanguages,
	translateText,
}
