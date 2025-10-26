Sequel.migration do
  change do
    rename_column :logs, :action, :activity
  end
end
