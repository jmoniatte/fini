Sequel.migration do
  change do
    create_table :logs do
      primary_key :id
      String :message
      String :text
      String :action
      String :tag
      Integer :duration
      DateTime :created_at
    end
  end
end
