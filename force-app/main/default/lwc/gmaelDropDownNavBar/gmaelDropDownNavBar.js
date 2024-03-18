/********************************************************************************************************************
* Globant
* Project:          Gmael - Intertek Portal
* Description:      LWC Custom Tabs.
* ______________________________________________________________________
* No.     Date           Author					 	Description
* ______________________________________________________________________
* 1.0     11/11/2023    Cristian Acero              Initial Version.
*********************************************************************************************************************/

import { LightningElement,api,wire, track } from 'lwc';
// import getContent from '@salesforce/apex/GSMManagedContentcc.getContent';
// import basePath from '@salesforce/community/basePath';
import intertek from '@salesforce/resourceUrl/intertek_gmael_images';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

var arrayContainer = [];
var arrowContainer = [];
var tabContainer = [];

var first = true;
var second = true;
var third = true;


let eventOutside;
let eventTab;

export default class GmaelDropDownNavBar extends NavigationMixin(LightningElement)  {
    @api contentId;
    @api title
    @api paragraph;
    @api item1;
    @api item2;
    @api item3;
    @api item4;
    @api item5;
    @api item6;
    @api item7;
    @api item8;
    @api boton;
    @api strUrl;
    @api links;
    @api isDisabled;

    @track linkPagina;
    url;    

    const = true;

    connectedCallback(){
        this.intertek = `${intertek}/${this.strUrl}`;
      }
   
    renderedCallback(){

        document.body.addEventListener("click", (evt) => {
            eventOutside = evt;
            if (this.const){
            contentTab.classList.add('hiddenTab');
            arrow.classList.add('hiddenTab');
             tabColor.classList.remove('tabColor');
            this.const = false;
            }else if(eventOutside.target !== eventTab.target){
                contentTab.classList.add('hidden');
                arrow.classList.add('hidden');
                tabColor.classList.remove('tabColor');
            }

        });

      
          
        var toggleButton = document.querySelector('.tabs__item.active'); 
        toggleButton.addEventListener('click', toggleElementVisibility);      
        const contentTab = this.template.querySelector('.container-dropdown');
        const arrow = document.querySelector('li.js-tab.active a span:nth-child(1)');
        const tabColor = document.querySelector('li.js-tab.active a');
        tabColor.classList.toggle('tabColor');
        arrayContainer.push(contentTab);
        arrowContainer.push(arrow);
        tabContainer.push(tabColor);

        function toggleElementVisibility(evt) {
           eventTab = evt;
           hideAll(contentTab,arrow,tabColor);
           contentTab.classList.toggle('hidden');  
           tabColor.classList.toggle('tabColor');
           contentTab.style.display = 'block';
           arrow.classList.toggle('hidden');  
           contentTab.classList.remove('hiddenTab');
           arrow.classList.remove('hiddenTab')

          }     
          
          function hideAll(evetcontentTab,evtArrow,evtTabColor){
        
            console.log(arrayContainer);
            arrayContainer.forEach(element => {

            if(element !== evetcontentTab){
                    element.className = 'container-dropdown hidden ';

             }else if(first){
                    first = false;
                    element.className = 'container-dropdown hidden ';
            }
        });
            arrowContainer.forEach(element => {
                if(element !== evtArrow){
                    element.className = 'arrow hidden';
                }else if(second){
                    second = false;
                    element.className = 'arrow hidden';
                }
            });
            tabContainer.forEach(element => {
                if(element !== evtTabColor){
                    element.className = 'tabHeader';
                }else if(third){
                    third = false;
                    element.className = 'tabHeader';
                }
            });
        }
     }

     handleSendRequest() {
        this.refs.sendARequestModel.handleShowModel();
    }
 }