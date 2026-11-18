module first_mod
 type :: item
  integer :: a
 contains
  procedure :: get => first_get
 end type
contains
 integer function first_get(this)
  class(item),intent(in) :: this
  first_get=this%a+100
 end function
end module
module second_mod
 type :: item
  integer :: a
 contains
  procedure :: get => second_get
 end type
contains
 integer function second_get(this)
  class(item),intent(in) :: this
  second_get=this%a+200
 end function
end module
program p
 use second_mod, only:item
 type(item) :: x
 x=item(3)
 print *,x%get()
end program
