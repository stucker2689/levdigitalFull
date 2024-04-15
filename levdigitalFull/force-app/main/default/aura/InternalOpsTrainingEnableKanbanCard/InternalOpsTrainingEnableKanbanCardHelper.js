({
    getColorFromText : function(stringToColor){
        let hash = 0;
        for (let i = 0; i < stringToColor.length; i++) {
          hash = stringToColor.charCodeAt(i) + ((hash << 5) - hash);
        }
        let color = '#';
        for (let i = 0; i < 3; i++) {
            let value = (hash >> (i * 8)) & 0xFF;
            color += ('00' + value.toString(16)).substr(-2);
        }
        color = this.lightenDarkenColor(color, 15);
        return color;
    },

    lightenDarkenColor: function(col, amt) {
        let usePound = false;    
        if (col[0] == "#") {
            col = col.slice(1);
            usePound = true;
        }    
        let num = parseInt(col,16);    
        let r = (num >> 16) + amt;    
        if (r > 255) r = 255;
        else if  (r < 0) r = 0;    
        let b = ((num >> 8) & 0x00FF) + amt;    
        if (b > 255) b = 255;
        else if  (b < 0) b = 0;    
        let g = (num & 0x0000FF) + amt;    
        if (g > 255) g = 255;
        else if (g < 0) g = 0;    
        return (usePound?"#":"") + (g | (b << 8) | (r << 16)).toString(16);
  
    },

    reverseString : function(str) {
        var newString = "";
        for (var i = str.length - 1; i >= 0; i--) {
            newString += str[i];
        }
        return newString;
    },

    getDistanceFromToday : function(sprintWeek){
        let oneDay = 24 * 60 * 60 * 1000; // hours*minutes*seconds*milliseconds
        let today = new Date();
        let sprintWeekDate = new Date(sprintWeek);
        let color;
        let diffDays = Math.round((sprintWeekDate - today) / oneDay);

        /*Different shades of Blue Gradient*/
        switch(true) {
            case (diffDays < -25 ):
                color = '#ff0000';
                break;
            case (diffDays < -20 ):
                color = '#d8003e';
                break;
            case (diffDays < -15 ):
                color = '#9b0054';
                break;
            case (diffDays < -10 ):
                color = '#550054';
                break;
            case (diffDays < -5 ):
                color = '#0c003e';
                break;
            case(diffDays < 5):
                color = '#1c009f';
                break;
            case(diffDays < 10):
                color = '#0044c4';
                break;
            case(diffDays < 15):
                color = '#006ddc';
                break;
            case(diffDays < 20):
                color = '#0093e8';
                break;
            case(diffDays < 25):
                color = '#00b6ee';
                break;
            case(diffDays < 30):
                color = '#68d8f4';
                break;
            case(diffDays < 35):
                color = '#afebff';
                break;
            default:
                color = '#bcbcbc';
                //color = '#b4f8ff';

        }
        return color;
    },

    moveItemInArray : function(arr, fromIndex, toIndex){
        while (fromIndex < 0) {
            fromIndex += arr.length;
        }
        while (toIndex < 0) {
            toIndex += arr.length;
        }
        if (toIndex >= arr.length) {
            var k = toIndex - arr.length;
            while ((k--) + 1) {
                arr.push(undefined);
            }
        }
         arr.splice(toIndex, 0, arr.splice(fromIndex, 1)[0]);  
       return arr;
    },
})