Sequel.migration do
  change do
    create_table :logs do
      primary_key :id
      String :message
      DateTime :done_at
      String :text
      String :action
      String :project
      Integer :duration
      DateTime :created_at
    end
  end
end
