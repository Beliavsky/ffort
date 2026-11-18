implicit none
character(4),parameter::a(2)=[character(2)::"a","bb"]
print *,a,a==["a   ","bb  "]
end
