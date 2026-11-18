program main
integer,target::a(-1:1)
integer,pointer::p(:)
a=[1,2,3]
p=>a
p(0)=9
if(a(0)/=9) error stop 1
if(.not.associated(p)) error stop 2
nullify(p)
if(associated(p)) error stop 3
p=>null()
end
