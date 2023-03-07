
window.onload = () => {

    console.log("hello world");

    /*const evtSource = new EventSource('/eventStream');

    evtSource.onmessage = function(event){
        console.log(event);
        console.log(event.data);
    }*/


    /*var tabs = [...document.querySelectorAll('.tab')];
    tabs[0].classList.add('active');
    console.log(tabs);
    for(var x of tabs){
        var res = M.Tabs.init(x);
        console.log(res);
    }
    var tabObjects = Object.fromEntries(
        tabs.map(x => [x.id, M.Tabs.init(x)]));


    console.log(tabObjects);

    let qrTab = tabObjects['qrTab'];
    console.log(qrTab);*/

    M.AutoInit();

    var tabsInstance = M.Tabs.getInstance(document.querySelector('.tabs'));

    tabsInstance.options.onShow = function(arg1){
        console.log("new tab");
        console.log(arg1);
        console.log(arg1.id);
    };
}
