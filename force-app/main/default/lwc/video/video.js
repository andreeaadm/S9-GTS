import {LightningElement, api} from 'lwc';

export default class Video extends LightningElement {
    @api src;

    onContextMenu(evt) {
        evt.preventDefault();
        return false;
    }

    @api playVideo() {
        this.template.querySelector('video').play();
    }

    @api pauseVideo() {
        this.template.querySelector('video').pause();
    }
}