Sequel.migration do
  change do
    create_table :logs do
      primary_key :id
      String :message
      DateTime :logged_at
      String :text
      String :action
      String :context
      Integer :duration
      DateTime :created_at
    end
  end
end
