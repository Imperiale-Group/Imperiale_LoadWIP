page 79401 "Sales Line Reservation"
{
    ApplicationArea = All;
    PageType = Worksheet;
    UsageCategory = Tasks;
    SourceTable = "Sales Line";
    SourceTableTemporary = true;
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = 'Associazione seriale a commessa';
    SourceTableView = sorting("Document No.", "Line No.");

    layout
    {
        area(Content)
        {
            field(Commessa; Commessa)
            {
                Caption = 'Commessa';
                ExtendedDatatype = Barcode;

                trigger OnValidate()
                begin
                    if Commessa <> '' then
                        UpdateFilters();
                end;

            }

            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    Caption = 'Nr. Articolo';
                }
                field(Description; Rec."Description")
                {
                    Caption = 'Descrizione';
                }
                field("SerialNo"; SerialNo)
                {
                    Caption = 'Nr. Seriale';

                    trigger OnValidate()
                    begin
                        if SerialNo <> '' then begin
                            CreateNewReservation(Rec, SerialNo);
                            Message('Seriale %1 associato', SerialNo);
                            SerialNo := '';
                            UpdateFilters();
                        end;

                    end;
                }
            }
        }
    }

    var
        Commessa: Code[20];
        SalesHeader: Record "Sales Header";
        SerialNo: Code[50];

    trigger OnOpenPage()
    begin
        Rec.Reset();
        UpdateFilters();
    end;

    local procedure UpdateFilters()
    var
        ReservationEntry: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
    begin
        Rec.DeleteAll();
        if Commessa > '' then begin
            SalesHeader.Reset();
            SalesHeader.SetRange("External Document No.", Commessa);
            if SalesHeader.FindFirst() then begin
                SalesLine.Reset();
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                SalesLine.Setrange("Document Type", SalesHeader."Document Type");
                if SalesLine.FindSet() then
                    repeat
                        if not HasReservation(SalesLine) then begin
                            Rec := SalesLine;
                            Rec.Insert();
                        end;
                    until SalesLine.Next() = 0
            end;
        end;
        CurrPage.Update(false);
    end;

    local procedure HasReservation(var SalesLine: Record "Sales Line"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", DATABASE::"Sales Line");
        ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
        ReservationEntry.SetRange("Item Tracking", ReservationEntry."Item Tracking"::"Serial No.");
        exit(ReservationEntry.Count = SalesLine.Quantity);
    end;

    local procedure CreateNewSerial(SalesLine: Record "Sales Line"; SerialNo: Code[20])
    var
        SNInfo: record "Serial No. Information";
        SalesHeader: Record "Sales Header";
    begin
        SNInfo.Reset();
        SNInfo.SetRange("Serial No.", SerialNo);
        SNInfo.SetRange("Item No.", SalesLine."No.");
        SNInfo.SetRange("Variant Code", SalesLine."Variant Code");
        if not SNInfo.FindFirst() then begin
            SalesHeader.Reset();
            SalesHeader.SetRange("No.", SalesLine."Document No.");
            SalesHeader.FindFirst();
            SNInfo.Reset();
            SNInfo.Init();
            SNInfo."Serial No." := SerialNo;
            SNInfo."Item No." := SalesLine."No.";
            SNInfo.Description := SalesLine.Description;
            SNInfo."Variant Code" := SalesLine."Variant Code";
            SNInfo."Job Number" := SalesHeader."External Document No.";
            SNInfo.Insert()
        end else
            Error('Seriale %1 già esistente', SerialNo);
    end;

    local procedure CreateNewReservation(SalesLine: Record "Sales Line"; NewSerial: Code[20])
    var
        NewReservationEntry: Record "Reservation Entry";
    begin
        CreateNewSerial(SalesLine, NewSerial);

        NewReservationEntry.Init();
        NewReservationEntry."Entry No." := NewReservationEntry.GetLastEntryNo() + 1;
        NewReservationEntry."Location Code" := SalesLine."Location Code";
        NewReservationEntry."Created By" := Database.UserId;
        NewReservationEntry."Creation Date" := Today;
        NewReservationEntry.Validate("Item No.", SalesLine."No.");
        if SalesLine."Variant Code" <> '' then
            NewReservationEntry."Variant Code" := SalesLine."Variant Code";
        NewReservationEntry."Reservation Status" := NewReservationEntry."Reservation Status"::Surplus;
        NewReservationEntry.Positive := false;
        NewReservationEntry."Source Type" := 37;
        NewReservationEntry."Source Subtype" := 1;
        NewReservationEntry."Source ID" := SalesLine."Document No.";
        NewReservationEntry."Source Ref. No." := SalesLine."Line No.";
        NewReservationEntry."Location Code" := SalesLine."Location Code";
        NewReservationEntry.Validate(Quantity, -1);
        NewReservationEntry."Qty. to Handle (Base)" := -1;
        NewReservationEntry."Qty. to Invoice (Base)" := -1;
        NewReservationEntry."Quantity (Base)" := -1;
        NewReservationEntry."Item Tracking" := NewReservationEntry."Item Tracking"::"Serial No.";
        if NewSerial <> '' then
            NewReservationEntry."Serial No." := NewSerial
        else
            NewReservationEntry."Serial No." := NewSerial;
        NewReservationEntry.Validate("Expected Receipt Date", Today);
        NewReservationEntry.Insert();

        CreateLoadWIPRecord(SalesLine."No.", NewSerial, SalesHeader."External Document No.");
    end;

    local procedure CreateLoadWIPRecord(ItemNo: Code[20]; SerialNo: Code[20]; JobNumber: Code[35])
    var
        LoadWIP: Record "LoadWIP";
    begin
        LoadWIP.Init();
        LoadWIP.ItemNo := ItemNo;
        LoadWIP.SerialNo := SerialNo;
        LoadWIP.Commessa := JobNumber;
        LoadWIP.Lot := SerialNo;
        LoadWIP.Insert();
    end;
}