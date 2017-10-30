Rails Event Store (RES) is a library for publishing, consuming, storing and retrieving events. It's your best companion for going with an event-driven architecture for your Rails application.

You can use it:

<ul class="default-ul">
<li>as your <a href="/docs/pubsub/">Publish-Subscribe bus</a></li>
<li>to decouple core business logic from external concerns in Hexagonal style architectures</li>
<li>as <a href="http://blog.arkency.com/2016/05/domain-events-over-active-record-callbacks/">an alternative to ActiveRecord callbacks and Observers</a></li>
<li>as a communication layer between loosely coupled components</li>
<li>to react to published events synchronously or asynchronously</li>
<li>to extract side-effects (notifications, metrics etc) from your controllers and services into event handlers</li>
<li>to build an audit-log</li>
<li>to create read-models</li>
<li>to implement event-sourcing</li>
</ul>