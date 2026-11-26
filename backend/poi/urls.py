from rest_framework.routers import DefaultRouter

from .views import PoiViewSet

router = DefaultRouter()
router.register('poi', PoiViewSet, basename='poi')

urlpatterns = router.urls
