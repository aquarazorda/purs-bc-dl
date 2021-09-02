exports.getRecord = (str) => {
    data = JSON.parse(str);
    ret = data.track.itemListElement
        .filter(item => typeof item.item.additionalProperty[2].value == "string")
        .map(item => ({
            name: item.item.name,
            link: item.item.additionalProperty[2].value
        }));

    return ret;
}