# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.Firewall do
  @moduledoc """
  Handler for PVE Firewall endpoints.

  Covers cluster-level and node-level firewall management:
  options, rules, security groups, aliases, and IP sets.
  """

  import Plug.Conn
  require Logger
  alias MockPveApi.State

  # ── Cluster Firewall Options ──

  def get_cluster_firewall_options(conn) do
    fw = State.get_firewall(:cluster)
    json_resp(conn, 200, fw.options)
  end

  def update_cluster_firewall_options(conn) do
    params = conn.body_params |> atomize_keys()
    fw = State.get_firewall(:cluster)
    new_options = Map.merge(fw.options, params)
    State.update_firewall(:cluster, %{options: new_options})
    json_resp(conn, 200, nil)
  end

  # ── Cluster Firewall Rules ──

  def list_cluster_firewall_rules(conn) do
    fw = State.get_firewall(:cluster)
    rules = rules_with_pos(fw.rules)
    json_resp(conn, 200, rules)
  end

  def create_cluster_firewall_rule(conn) do
    params = conn.body_params
    rule = build_rule(params)
    fw = State.get_firewall(:cluster)
    new_rules = fw.rules ++ [rule]
    State.update_firewall(:cluster, %{rules: new_rules})
    json_resp(conn, 200, nil)
  end

  def get_cluster_firewall_rule(conn) do
    pos = parse_pos(conn.path_params["pos"])
    fw = State.get_firewall(:cluster)

    case Enum.at(fw.rules, pos) do
      nil -> json_error(conn, 400, "no rule at position #{pos}")
      rule -> json_resp(conn, 200, Map.put(rule, :pos, pos))
    end
  end

  def update_cluster_firewall_rule(conn) do
    pos = parse_pos(conn.path_params["pos"])
    params = conn.body_params
    fw = State.get_firewall(:cluster)

    case Enum.at(fw.rules, pos) do
      nil ->
        json_error(conn, 400, "no rule at position #{pos}")

      rule ->
        updated = Map.merge(rule, build_rule(params))
        new_rules = List.replace_at(fw.rules, pos, updated)
        State.update_firewall(:cluster, %{rules: new_rules})
        json_resp(conn, 200, nil)
    end
  end

  def delete_cluster_firewall_rule(conn) do
    pos = parse_pos(conn.path_params["pos"])
    fw = State.get_firewall(:cluster)

    if pos < length(fw.rules) do
      new_rules = List.delete_at(fw.rules, pos)
      State.update_firewall(:cluster, %{rules: new_rules})
      json_resp(conn, 200, nil)
    else
      json_error(conn, 400, "no rule at position #{pos}")
    end
  end

  # ── Security Groups ──

  def list_security_groups(conn) do
    fw = State.get_firewall(:cluster)

    groups =
      Enum.map(fw.groups, fn {name, group} ->
        %{group: name, comment: Map.get(group, :comment, ""), rules: length(group.rules)}
      end)

    json_resp(conn, 200, groups)
  end

  def create_security_group(conn) do
    params = conn.body_params
    name = Map.get(params, "group")

    if name do
      fw = State.get_firewall(:cluster)

      if Map.has_key?(fw.groups, name) do
        json_error(conn, 400, "security group '#{name}' already exists")
      else
        group = %{comment: Map.get(params, "comment", ""), rules: []}
        new_groups = Map.put(fw.groups, name, group)
        State.update_firewall(:cluster, %{groups: new_groups})
        json_resp(conn, 200, nil)
      end
    else
      json_error(conn, 400, "property 'group' is missing and it is not optional")
    end
  end

  def get_security_group(conn) do
    group_name = conn.path_params["group"]
    fw = State.get_firewall(:cluster)

    case Map.get(fw.groups, group_name) do
      nil -> json_error(conn, 404, "no such security group '#{group_name}'")
      group -> json_resp(conn, 200, rules_with_pos(group.rules))
    end
  end

  def delete_security_group(conn) do
    group_name = conn.path_params["group"]
    fw = State.get_firewall(:cluster)

    if Map.has_key?(fw.groups, group_name) do
      new_groups = Map.delete(fw.groups, group_name)
      State.update_firewall(:cluster, %{groups: new_groups})
      json_resp(conn, 200, nil)
    else
      json_error(conn, 404, "no such security group '#{group_name}'")
    end
  end

  def get_security_group_rule(conn) do
    group_name = conn.path_params["group"]
    pos = parse_pos(conn.path_params["pos"])
    fw = State.get_firewall(:cluster)

    case Map.get(fw.groups, group_name) do
      nil ->
        json_error(conn, 404, "no such security group '#{group_name}'")

      group ->
        case Enum.at(group.rules, pos) do
          nil -> json_error(conn, 400, "no rule at position #{pos}")
          rule -> json_resp(conn, 200, Map.put(rule, :pos, pos))
        end
    end
  end

  def update_security_group_rule(conn) do
    group_name = conn.path_params["group"]
    pos = parse_pos(conn.path_params["pos"])
    params = conn.body_params
    fw = State.get_firewall(:cluster)

    case Map.get(fw.groups, group_name) do
      nil ->
        json_error(conn, 404, "no such security group '#{group_name}'")

      group ->
        case Enum.at(group.rules, pos) do
          nil ->
            json_error(conn, 400, "no rule at position #{pos}")

          rule ->
            updated = Map.merge(rule, build_rule(params))
            new_rules = List.replace_at(group.rules, pos, updated)
            new_group = %{group | rules: new_rules}
            new_groups = Map.put(fw.groups, group_name, new_group)
            State.update_firewall(:cluster, %{groups: new_groups})
            json_resp(conn, 200, nil)
        end
    end
  end

  def delete_security_group_rule(conn) do
    group_name = conn.path_params["group"]
    pos = parse_pos(conn.path_params["pos"])
    fw = State.get_firewall(:cluster)

    case Map.get(fw.groups, group_name) do
      nil ->
        json_error(conn, 404, "no such security group '#{group_name}'")

      group ->
        if pos < length(group.rules) do
          new_rules = List.delete_at(group.rules, pos)
          new_group = %{group | rules: new_rules}
          new_groups = Map.put(fw.groups, group_name, new_group)
          State.update_firewall(:cluster, %{groups: new_groups})
          json_resp(conn, 200, nil)
        else
          json_error(conn, 400, "no rule at position #{pos}")
        end
    end
  end

  # ── Cluster Aliases ──

  def list_aliases(conn) do
    fw = State.get_firewall(:cluster)

    aliases =
      Enum.map(fw.aliases, fn {name, alias_entry} ->
        Map.merge(alias_entry, %{name: name})
      end)

    json_resp(conn, 200, aliases)
  end

  def create_alias(conn) do
    params = conn.body_params
    name = Map.get(params, "name")

    if name do
      fw = State.get_firewall(:cluster)

      if Map.has_key?(fw.aliases, name) do
        json_error(conn, 400, "alias '#{name}' already exists")
      else
        alias_entry = %{
          cidr: Map.get(params, "cidr", ""),
          comment: Map.get(params, "comment", "")
        }

        new_aliases = Map.put(fw.aliases, name, alias_entry)
        State.update_firewall(:cluster, %{aliases: new_aliases})
        json_resp(conn, 200, nil)
      end
    else
      json_error(conn, 400, "property 'name' is missing and it is not optional")
    end
  end

  def get_alias(conn) do
    name = conn.path_params["name"]
    fw = State.get_firewall(:cluster)

    case Map.get(fw.aliases, name) do
      nil -> json_error(conn, 404, "no such alias '#{name}'")
      alias_entry -> json_resp(conn, 200, Map.put(alias_entry, :name, name))
    end
  end

  def update_alias(conn) do
    name = conn.path_params["name"]
    params = conn.body_params
    fw = State.get_firewall(:cluster)

    case Map.get(fw.aliases, name) do
      nil ->
        json_error(conn, 404, "no such alias '#{name}'")

      alias_entry ->
        updated =
          alias_entry
          |> maybe_put(:cidr, Map.get(params, "cidr"))
          |> maybe_put(:comment, Map.get(params, "comment"))

        new_aliases = Map.put(fw.aliases, name, updated)
        State.update_firewall(:cluster, %{aliases: new_aliases})
        json_resp(conn, 200, nil)
    end
  end

  def delete_alias(conn) do
    name = conn.path_params["name"]
    fw = State.get_firewall(:cluster)

    if Map.has_key?(fw.aliases, name) do
      new_aliases = Map.delete(fw.aliases, name)
      State.update_firewall(:cluster, %{aliases: new_aliases})
      json_resp(conn, 200, nil)
    else
      json_error(conn, 404, "no such alias '#{name}'")
    end
  end

  # ── Cluster IP Sets ──

  def list_ipsets(conn) do
    fw = State.get_firewall(:cluster)

    ipsets =
      Enum.map(fw.ipsets, fn {name, ipset} ->
        %{name: name, comment: Map.get(ipset, :comment, ""), count: length(ipset.entries)}
      end)

    json_resp(conn, 200, ipsets)
  end

  def create_ipset(conn) do
    params = conn.body_params
    name = Map.get(params, "name")

    if name do
      fw = State.get_firewall(:cluster)

      if Map.has_key?(fw.ipsets, name) do
        json_error(conn, 400, "IP set '#{name}' already exists")
      else
        ipset = %{comment: Map.get(params, "comment", ""), entries: []}
        new_ipsets = Map.put(fw.ipsets, name, ipset)
        State.update_firewall(:cluster, %{ipsets: new_ipsets})
        json_resp(conn, 200, nil)
      end
    else
      json_error(conn, 400, "property 'name' is missing and it is not optional")
    end
  end

  def get_ipset(conn) do
    name = conn.path_params["name"]
    fw = State.get_firewall(:cluster)

    case Map.get(fw.ipsets, name) do
      nil -> json_error(conn, 404, "no such IP set '#{name}'")
      ipset -> json_resp(conn, 200, ipset.entries)
    end
  end

  def delete_ipset(conn) do
    name = conn.path_params["name"]
    fw = State.get_firewall(:cluster)

    if Map.has_key?(fw.ipsets, name) do
      new_ipsets = Map.delete(fw.ipsets, name)
      State.update_firewall(:cluster, %{ipsets: new_ipsets})
      json_resp(conn, 200, nil)
    else
      json_error(conn, 404, "no such IP set '#{name}'")
    end
  end

  def get_ipset_entry(conn) do
    name = conn.path_params["name"]
    cidr = cidr_from_path(conn.path_params["cidr"])
    fw = State.get_firewall(:cluster)

    case Map.get(fw.ipsets, name) do
      nil ->
        json_error(conn, 404, "no such IP set '#{name}'")

      ipset ->
        case Enum.find(ipset.entries, &(&1.cidr == cidr)) do
          nil -> json_error(conn, 404, "no such entry '#{cidr}' in IP set '#{name}'")
          entry -> json_resp(conn, 200, entry)
        end
    end
  end

  def update_ipset_entry(conn) do
    name = conn.path_params["name"]
    cidr = cidr_from_path(conn.path_params["cidr"])
    params = conn.body_params
    fw = State.get_firewall(:cluster)

    case Map.get(fw.ipsets, name) do
      nil ->
        json_error(conn, 404, "no such IP set '#{name}'")

      ipset ->
        case Enum.find_index(ipset.entries, &(&1.cidr == cidr)) do
          nil ->
            json_error(conn, 404, "no such entry '#{cidr}' in IP set '#{name}'")

          idx ->
            entry = Enum.at(ipset.entries, idx)

            updated =
              entry
              |> maybe_put(:comment, Map.get(params, "comment"))
              |> maybe_put(:nomatch, Map.get(params, "nomatch"))

            new_entries = List.replace_at(ipset.entries, idx, updated)
            new_ipset = %{ipset | entries: new_entries}
            new_ipsets = Map.put(fw.ipsets, name, new_ipset)
            State.update_firewall(:cluster, %{ipsets: new_ipsets})
            json_resp(conn, 200, nil)
        end
    end
  end

  def delete_ipset_entry(conn) do
    name = conn.path_params["name"]
    cidr = cidr_from_path(conn.path_params["cidr"])
    fw = State.get_firewall(:cluster)

    case Map.get(fw.ipsets, name) do
      nil ->
        json_error(conn, 404, "no such IP set '#{name}'")

      ipset ->
        new_entries = Enum.reject(ipset.entries, &(&1.cidr == cidr))

        if length(new_entries) == length(ipset.entries) do
          json_error(conn, 404, "no such entry '#{cidr}' in IP set '#{name}'")
        else
          new_ipset = %{ipset | entries: new_entries}
          new_ipsets = Map.put(fw.ipsets, name, new_ipset)
          State.update_firewall(:cluster, %{ipsets: new_ipsets})
          json_resp(conn, 200, nil)
        end
    end
  end

  # To add CIDR entries to an ipset, use POST on the ipset name endpoint
  # with a "cidr" param. PVE API re-uses GET /{name} to list entries and
  # POST /{name} isn't in the plan, but we handle it for completeness.
  def add_ipset_entry(conn) do
    name = conn.path_params["name"]
    params = conn.body_params
    cidr = Map.get(params, "cidr")

    if cidr do
      fw = State.get_firewall(:cluster)

      case Map.get(fw.ipsets, name) do
        nil ->
          json_error(conn, 404, "no such IP set '#{name}'")

        ipset ->
          if Enum.any?(ipset.entries, &(&1.cidr == cidr)) do
            json_error(conn, 400, "entry '#{cidr}' already exists in IP set '#{name}'")
          else
            entry = %{
              cidr: cidr,
              comment: Map.get(params, "comment", ""),
              nomatch: Map.get(params, "nomatch", false)
            }

            new_ipset = %{ipset | entries: ipset.entries ++ [entry]}
            new_ipsets = Map.put(fw.ipsets, name, new_ipset)
            State.update_firewall(:cluster, %{ipsets: new_ipsets})
            json_resp(conn, 200, nil)
          end
      end
    else
      json_error(conn, 400, "property 'cidr' is missing and it is not optional")
    end
  end

  # ── Node Firewall Options ──

  def get_node_firewall_options(conn) do
    node = conn.path_params["node"]
    fw = State.get_firewall({:node, node})
    json_resp(conn, 200, fw.options)
  end

  def update_node_firewall_options(conn) do
    node = conn.path_params["node"]
    params = conn.body_params |> atomize_keys()
    fw = State.get_firewall({:node, node})
    new_options = Map.merge(fw.options, params)
    State.update_firewall({:node, node}, %{options: new_options})
    json_resp(conn, 200, nil)
  end

  # ── Node Firewall Rules ──

  def list_node_firewall_rules(conn) do
    node = conn.path_params["node"]
    fw = State.get_firewall({:node, node})
    json_resp(conn, 200, rules_with_pos(fw.rules))
  end

  def create_node_firewall_rule(conn) do
    node = conn.path_params["node"]
    params = conn.body_params
    rule = build_rule(params)
    fw = State.get_firewall({:node, node})
    new_rules = fw.rules ++ [rule]
    State.update_firewall({:node, node}, %{rules: new_rules})
    json_resp(conn, 200, nil)
  end

  def get_node_firewall_rule(conn) do
    node = conn.path_params["node"]
    pos = parse_pos(conn.path_params["pos"])
    fw = State.get_firewall({:node, node})

    case Enum.at(fw.rules, pos) do
      nil -> json_error(conn, 400, "no rule at position #{pos}")
      rule -> json_resp(conn, 200, Map.put(rule, :pos, pos))
    end
  end

  def update_node_firewall_rule(conn) do
    node = conn.path_params["node"]
    pos = parse_pos(conn.path_params["pos"])
    params = conn.body_params
    fw = State.get_firewall({:node, node})

    case Enum.at(fw.rules, pos) do
      nil ->
        json_error(conn, 400, "no rule at position #{pos}")

      rule ->
        updated = Map.merge(rule, build_rule(params))
        new_rules = List.replace_at(fw.rules, pos, updated)
        State.update_firewall({:node, node}, %{rules: new_rules})
        json_resp(conn, 200, nil)
    end
  end

  def delete_node_firewall_rule(conn) do
    node = conn.path_params["node"]
    pos = parse_pos(conn.path_params["pos"])
    fw = State.get_firewall({:node, node})

    if pos < length(fw.rules) do
      new_rules = List.delete_at(fw.rules, pos)
      State.update_firewall({:node, node}, %{rules: new_rules})
      json_resp(conn, 200, nil)
    else
      json_error(conn, 400, "no rule at position #{pos}")
    end
  end

  # ── Private Helpers ──

  defp json_resp(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(%{data: data}))
  end

  defp json_error(conn, status, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(%{errors: %{message: message}}))
  end

  defp build_rule(params) do
    %{
      type: Map.get(params, "type", "in"),
      action: Map.get(params, "action", "ACCEPT"),
      enable: Map.get(params, "enable", 1),
      comment: Map.get(params, "comment", ""),
      source: Map.get(params, "source"),
      dest: Map.get(params, "dest"),
      proto: Map.get(params, "proto"),
      dport: Map.get(params, "dport"),
      sport: Map.get(params, "sport"),
      macro: Map.get(params, "macro"),
      iface: Map.get(params, "iface"),
      log: Map.get(params, "log")
    }
  end

  defp rules_with_pos(rules) do
    rules
    |> Enum.with_index()
    |> Enum.map(fn {rule, idx} -> Map.put(rule, :pos, idx) end)
  end

  defp parse_pos(pos_str) do
    case Integer.parse(pos_str) do
      {pos, _} -> pos
      :error -> 0
    end
  end

  defp cidr_from_path(cidr_param) do
    # URL paths use dash notation (10.0.0.0-24) to avoid path separator conflicts
    String.replace(cidr_param, "-", "/")
  end

  defp atomize_keys(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
