implicit none
character(3)::a(3)=[character(3)::"abcd","b","cde"]
print *,a,a==["abc","b  ","cde"]
end
