({
    showToastMessage: function (component, variant, title, message) {
        $A.get("e.force:showToast").setParams({ "type": variant, "title": title, "message": message }).fire();
    },

    navigate: function (url) {
        $A.get("e.force:navigateToURL").setParams({ "url": url }).fire();
    },
})