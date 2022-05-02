import React from 'react';
import PlayerViews from './PlayerViews';

const exports = { ...PlayerViews };

const sleep = (milliseconds) => new Promise(resolve => setTimeout(resolve, milliseconds));

exports.Wrapper = class extends React.Component {
  render() {
    const { content } = this.props;
    return (
      <div className="Deployer">
        <h2>Event Organizer</h2>
        {content}
      </div>
    );
  }
}

exports.SetEventFee = class extends React.Component {
  render() {
    const { parent, defaultEventFee, standardUnit } = this.props;
    const eventFee = (this.state || {}).eventFee || defaultEventFee;
    return (
      <div>
        <label>Evenet Fee  {standardUnit}</label>
        <div class="input-group">
          <input
            type='number'
            placeholder={defaultEventFee}
            onChange={(e) => this.setState({ eventFee: e.currentTarget.value })}
          />
        </div>
        <br />
        <button
          onClick={() => parent.setEventFee(eventFee)}
        >New Event</button>
      </div>
    );
  }
}

exports.Deploy = class extends React.Component {
  render() {
    const { parent, eventFee, standardUnit } = this.props;
    return (
      <div>
        Event Details Confirmation:
        <br />
        Event Fee: <strong>{eventFee}</strong> {standardUnit}
        <br />
        <button
          onClick={() => parent.deploy()}
        >Create Event</button>
      </div>
    );
  }
}

exports.Deploying = class extends React.Component {
  render() {
    return (
      <div>Deploying... please wait.</div>
    );
  }
}

exports.WaitingForAttacher = class extends React.Component {
  async copyToClipboard(button) {
    const { ctcInfoStr } = this.props;
    navigator.clipboard.writeText(ctcInfoStr);
    const origInnerHTML = button.innerHTML;
    button.innerHTML = 'Copied!';
    button.disabled = true;
    await sleep(1000);
    button.innerHTML = origInnerHTML;
    button.disabled = false;
  }

  render() {
    const { ctcInfoStr } = this.props;
    return (
      <div>
        Event was created successfully...
        <br /> Please give them this contract info to buy tickets:
        <pre className='ContractInfo'>
          {ctcInfoStr}
        </pre>
        <button
          onClick={(e) => this.copyToClipboard(e.currentTarget)}
        >Copy to clipboard</button>
      </div>
    )
  }
}

// Player views must be extended.
// It does not have its own Wrapper view.

exports.ApproveInvitee = class extends React.Component {
  render() {
    const { parent, playable } = this.props;
    return (
      <div>
        <br />
        The client has rsvp'd, Approve or Decline...
        <br />
        <br />
        <div>
          <button
            disabled={!playable}
            onClick={() => parent.playHand('APPROVE')}
          >Approve</button>
        </div>
        <br />
        <div>
          <button
            disabled={!playable}
            onClick={() => parent.playHand('DECLINE')}
          >Decline</button>
        </div>
      </div>
    );
  }
}

export default exports;
