<%@ page contentType="text/html;charset=UTF-8" %>
<!-- Click on any image with class "zoomable" to see it big. Click anywhere or press Esc to close. -->
<div class="lightbox" id="lightbox"><img id="lightboxImg" alt="Event image"></div>
<script>
(function () {
  var box = document.getElementById('lightbox');
  var big = document.getElementById('lightboxImg');
  document.querySelectorAll('.zoomable').forEach(function (img) {
    img.addEventListener('click', function () {
      big.src = img.getAttribute('data-full') || img.src;
      box.classList.add('open');
    });
  });
  box.addEventListener('click', function () { box.classList.remove('open'); });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') box.classList.remove('open');
  });
})();
</script>
