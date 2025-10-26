Sequel.migration do
  change do
    rename_column :logs, :tag, :scope
  end
end
