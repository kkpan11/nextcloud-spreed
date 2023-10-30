<?php

declare(strict_types=1);
/**
 * @copyright Copyright (c) 2023 Joas Schilling <coding@schilljs.com>
 *
 * @license GNU AGPL version 3 or any later version
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

namespace OCA\Talk\Collaboration\Resources;

use OCA\Talk\Events\ARoomModifiedEvent;
use OCA\Talk\Events\AttendeesAddedEvent;
use OCA\Talk\Events\AttendeesRemovedEvent;
use OCA\Talk\Events\EmailInvitationSentEvent;
use OCA\Talk\Events\RoomDeletedEvent;
use OCA\Talk\Events\RoomModifiedEvent;
use OCP\Collaboration\Resources\IManager;
use OCP\Collaboration\Resources\ResourceException;
use OCP\EventDispatcher\Event;
use OCP\EventDispatcher\IEventListener;

/**
 * @template-implements IEventListener<Event>
 */
class Listener implements IEventListener {
	public function __construct(
		protected IManager $resourceManager,
	) {
	}

	public function handle(Event $event): void {
		if ($event instanceof AttendeesAddedEvent
			|| $event instanceof AttendeesRemovedEvent
			|| $event instanceof RoomDeletedEvent
			|| $event instanceof EmailInvitationSentEvent
			|| ($event instanceof RoomModifiedEvent
				&& $event->getProperty() === ARoomModifiedEvent::PROPERTY_TYPE)) {
			try {
				$resource = $this->resourceManager->getResourceForUser('room', $event->getRoom()->getToken(), null);
			} catch (ResourceException) {
				return;
			}
			$this->resourceManager->invalidateAccessCacheForResource($resource);
		}
	}
}
