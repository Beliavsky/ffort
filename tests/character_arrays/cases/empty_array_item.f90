implicit none
character(2)::a(0)
character(2)::b(1)
b=[character(2)::a,"z"]
print *,b
end
