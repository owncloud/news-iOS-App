function FDGetHTMLElementsAtPoint(x, y) {
   var tags = ",";
   var e = document.elementFromPoint(x,y);
   while (e) {
      if (e.tagName) {
         tags += e.tagName + ',';
      }
      e = e.parentNode;
   }
   return tags;
}