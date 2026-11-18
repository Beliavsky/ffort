implicit none
character(2)::a(2)=["aa","bb"]
a(2)="xyz"
print *,a(1)//a(2),a
end
