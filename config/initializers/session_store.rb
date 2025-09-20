Rails.application.config.session_store :cookie_store,
                                       key: '_loopin_session', # 任意の名前
                                       secure: Rails.env.production?, # 本番では true
                                       same_site: :lax
