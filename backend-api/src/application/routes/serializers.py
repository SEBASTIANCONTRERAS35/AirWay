from rest_framework import serializers

class RouteQuery(serializers.Serializer):
    origin = serializers.ListField(child=serializers.FloatField(), min_length=2, max_length=2)
    destination = serializers.ListField(child=serializers.FloatField(), min_length=2, max_length=2)
    mode = serializers.ChoiceField(choices=("walk","run","bike"))
    optimize = serializers.ChoiceField(choices=("shortest","healthiest","hybrid"))
    depart_at = serializers.DateTimeField(required=False)
    aqi_threshold = serializers.IntegerField(required=False, min_value=0, max_value=500)

class ScoreQuery(serializers.Serializer):
    polyline = serializers.CharField()
    mode = serializers.ChoiceField(choices=("walk","run","bike"))
    depart_at = serializers.DateTimeField(required=False)