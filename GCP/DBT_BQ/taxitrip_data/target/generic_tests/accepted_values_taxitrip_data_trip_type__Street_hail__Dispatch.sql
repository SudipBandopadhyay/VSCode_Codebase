{{ config({}) }}
{{ test_accepted_values(column_name="trip_type", model=get_where_subquery(ref('taxitrip_data')), values=["Street-hail","Dispatch"]) }}