# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_04_09_042818) do
  create_table "contract_prompts", force: :cascade do |t|
    t.integer "contract_id", null: false
    t.text "prompt_text"
    t.text "response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id"], name: "index_contract_prompts_on_contract_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.text "content"
    t.string "contract_type"
    t.text "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "output_format", default: "JSON", null: false
    t.string "llm_provider", default: "Gemini", null: false
    t.json "summary_json"
  end

  add_foreign_key "contract_prompts", "contracts"
end
