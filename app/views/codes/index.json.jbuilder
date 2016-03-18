json.array!(@codes) do |code|
  json.extract! code, :id, :code, :user_id, :file_name
  json.url code_url(code, format: :json)
end
