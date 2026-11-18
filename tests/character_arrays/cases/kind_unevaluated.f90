implicit none
character(2)::a(2)
print *,kind(a//"!"),kind([character(3)::a]),kind(a=="a")
end
