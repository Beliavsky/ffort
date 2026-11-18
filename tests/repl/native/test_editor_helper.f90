program test_editor_helper
    use fi_repl_editor
    implicit none
    character(:),allocatable::result,message,body
    logical::handled
    integer::n,checks
    checks=0;body='a'//achar(10)//'b'//achar(10)//'c'//achar(10)
    call edit('.del :',body,'',0)
    call edit('.del :2',body,'c'//achar(10),1)
    call edit('.del 2:',body,'a'//achar(10),1)
    call edit('.del 2',body,'a'//achar(10)//'c'//achar(10),2)
    call edit('.ins 1 z','', 'z'//achar(10),1)
    call edit('.ins 4 z',body,body//'z'//achar(10),4)
    call edit('.rep 3 z',body,'a'//achar(10)//'b'//achar(10)//'z'//achar(10),3)
    call bad('.del 2147483648',body)
    call bad('.del -1',body)
    call bad('.del 1:2 junk',body)
    call bad('.rep 1x',body)
    call bad('.rep 1 '//achar(13)//'x',body)
    call bad('.rep 1 '//achar(0)//'x',body)
    call bad('.rep 1 x'//achar(10)//'y',body)
    call edit_repl_body('.ins 1 abc','',2,10,100,handled,result,n,message)
    call check(handled.and.len(message)>0.and..not.allocated(result))
    call edit_repl_body('.ins 4 z',body,10,3,100,handled,result,n,message)
    call check(handled.and.len(message)>0.and..not.allocated(result))
    call edit_repl_body('.rep 2 zzz',body,10,10,6,handled,result,n,message)
    call check(handled.and.len(message)>0.and..not.allocated(result))
    call edit_repl_body('.replica 1 z',body,10,10,100,handled,result,n,message)
    call check(.not.handled.and..not.allocated(result))
    print '(a,i0)', 'PASS helper contracts: ',checks
contains
    subroutine check(ok)
        logical,intent(in)::ok
        checks=checks+1
        if(.not.ok)then
            print *, 'failed check ',checks
            stop 1
        end if
    end subroutine
    subroutine edit(command,input,expected,lines)
        character(*),intent(in)::command,input,expected
        integer,intent(in)::lines
        call edit_repl_body(command,input,100,100,1000,handled,result,n,message)
        call check(handled.and.len(message)==0)
        call check(allocated(result))
        call check(result==expected.and.n==lines)
    end subroutine
    subroutine bad(command,input)
        character(*),intent(in)::command,input
        call edit_repl_body(command,input,100,100,1000,handled,result,n,message)
        call check(handled.and.len(message)>0.and..not.allocated(result))
    end subroutine
end program
