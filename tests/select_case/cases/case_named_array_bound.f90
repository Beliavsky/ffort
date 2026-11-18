program p
implicit none
integer,parameter::a(2)=[1,3]
select case(2)
case(a(1):a(2))
print *,1
end select
end program p
