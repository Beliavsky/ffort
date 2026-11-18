program p
implicit none
integer,parameter::a(3)=[1,2,3]
integer::b(-1:2,3)
integer,parameter::sa(1)=shape(a),sb(2)=shape(b)
integer(kind=8),parameter::wide(2)=shape(b,kind=8)
print *,sa,sb,wide,kind(wide)
end program
