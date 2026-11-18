implicit none
character(2)::a(2)=["ab","cd"]
character(3)::b(5)
b=[character(3)::a,"e",a]
print *,b
end
