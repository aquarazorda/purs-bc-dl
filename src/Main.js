exports.getRecord = (str) => {
    data = JSON.parse(str);
    ret = data.track.itemListElement.map(item => ({
        name: item.item.name,
        link: item.item.additionalProperty[2].value
    }));
    
    return ret;
}