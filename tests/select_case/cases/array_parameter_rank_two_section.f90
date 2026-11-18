program p
implicit none
integer,parameter::a(2,2)=1
integer,parameter::b(2,2)=a(:,:)
print *,b
end program p
